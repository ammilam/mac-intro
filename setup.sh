#! /bin/bash -e
################################
##### Author: Andrew Milam #####
################################

######################################
##### Verifies Tool Installation #####
######################################
which jq 2>&1 >/dev/null || (echo "Error, jq executable is required" && exit 1) || exit 1
which terraform 2>&1 >/dev/null || (echo "Error, terracorm executable is required" && exit 1) || exit 1
which gcloud 2>&1 >/dev/null || (echo "Error, gcloud executable is required" && exit 1) || exit 1


#####################################
##### Sets GCP Project Variable #####
#####################################
echo ""
export PROJECT="$(gcloud config get-value project)"
echo "Your current configured gcloud project is $PROJECT"
echo ""
echo "This will deploy a gke cluster with gitlab, an intentionally broken flux, prometheus stack, helm operator, and gcp logging/monitoring/alerts."
echo "The gcp alert created will instruct you on how to resolve the broken flux and is intended to demonstrate monitoring as code functionality."
sleep 2
echo ""

# sets git specific variables
export URL="$(git config --get remote.origin.url)"
export EMAIL="$(gcloud config get-value account)"


####################################
##### Git Hub & Repo Variables #####
####################################
echo ""
sleep 2
basename=$(basename $URL)
re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
if [[ $URL =~ $re ]]; then
    USERNAME=${BASH_REMATCH[4]}
    REPO=${BASH_REMATCH[5]}
fi
echo ""
echo "Git is configured for user $USERNAME on the $REPO repository."
echo ""
sleep 2


#######################################################
##### Sets Github Personal Access Token Parameter #####
#######################################################
TOKEN=$(cat token)
if [[ -z $TOKEN ]]
then
    # prompts for github personal access token
    read -p "Enter a github personal access token: " TOKEN
    echo $TOKEN > token
fi


##################################################
##### Service Account Creation For Terraform #####
##################################################
SA_NAME="terraform-${PROJECT}"
GCP_USER=$(gcloud config get-value account)

if [[ -z $(gcloud iam service-accounts list|grep $SA_NAME) ]]
then
    gcloud iam service-accounts create $SA_NAME
fi

gcloud projects add-iam-policy-binding $PROJECT --member="user:${GCP_USER}" --role="roles/owner"
gcloud projects add-iam-policy-binding $PROJECT --member="user:${GCP_USER}" --role="roles/storage.admin"
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com" --role="roles/owner"
if [[ ! -f "account.json" ]]
then
    gcloud iam service-accounts keys create ./"account.json" --iam-account "${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"
fi


###############################################
##### Sets Google Application Credentials #####
###############################################

export GOOGLE_APPLICATION_CREDENTIALS="account.json"

##################################################
##### Terraform Remote State Bucket Creation #####
##################################################
echo "
terraform {
  backend "\"gcs\""{
    bucket      = "\"${PROJECT}-terraform-state\""
    prefix      = "\"sandbox\""
    credentials = "\"account.json\""
  }
}
" > backend.tf

if [[ -z $(gsutil ls|grep $PROJECT-terraform-state) ]]
then
    gsutil mb gs://$PROJECT-terraform-state
fi

##################################################################
##### Abstracting Existing Cluster Name From Terraform State #####
##################################################################
# checks if terraform state file exists, if it does - sets the cluster_name to the output in the state file
terraform init

echo "checking if a local copy of terraform.tfstate exists"
echo ""

if [[ ! -f terraform.tfstate ]]
then
    if [[ $(terraform state pull|jq '.resources') == "[]" ]]
    then
        read -p "Enter a cluster name: " NAME
    fi
fi

if [[ ! -f terraform.tfstate ]]
then
    if [[ $(terraform output cluster_name) ]];
    then export NAME=$(terraform output cluster_name)
    echo ""
        echo "Your existing cluster is called $NAME"
        echo ""
        sleep 2
    fi
fi
if [[ -f terraform.tfstate ]]
then
    if [[ $(cat terraform.tfstate|jq -r '.outputs.cluster_name.value') != "null" ]]
    then
        export NAME="$(cat terraform.tfstate|jq -r '.outputs.cluster_name.value')"
        echo "Your existing cluster is called $NAME"
        echo ""
        sleep 2
    fi
    if [[ $(cat terraform.tfstate|jq -r '.outputs.cluster_name.value') == "null" ]]
    then
        read -p "Enter a cluster name: " NAME
    fi
fi


##########################################
##### Terraform Apply With Variables #####
##########################################
echo ""
sleep 5
terraform fmt --recursive
terraform apply -var "google_credentials=${GOOGLE_APPLICATION_CREDENTIALS}" -var "repo=${REPO}" -var "github_token=${TOKEN}" -var "username=${USERNAME}" -var "email_address=${EMAIL}" -var "cluster_name=${NAME}" -var "project_id=${PROJECT}" -auto-approve
sleep 5
terraform state pull > terraform.tfstate

##################################################
##### Sets Kubernetes Context To GKE CLuster #####
##################################################

export REGION=$(terraform output location)
echo ""
echo "Getting kubeconfig for the GKE cluster..."
echo ""
sleep 2
gcloud container clusters get-credentials $NAME --zone $REGION --project $PROJECT -q
echo ""

if [[ -z $(kubectl get secrets -o json|jq -r '.items[].metadata.name'|grep my-secret) ]]
then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 --keyout tls.key -out tls.crt -subj "/CN=fake.gitlab.com"
    kubectl create secret tls my-secret --key="tls.key" --cert="tls.crt"
    rm tls.*
fi

######################################
##### Sets User As Cluster Admin #####
######################################
if [[ -z $(kubectl get clusterrolebinding cluster-admin-binding) ]]
then
    echo "Setting current user as cluster admin"
    echo ""
    sleep 2
    kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)
    echo ""
fi

echo ""
echo "A GCP Service Account key for $SA_NAME has been generated at the root of this module."
echo "That Service Account has elivated rights over the project $PROJECT."
echo "./cleanup.sh can be used to run terraform destroy, script will also cleanup the generated service account key"
echo ""
