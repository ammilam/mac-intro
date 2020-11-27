#! /bin/bash

echo "This installation takes place in a few parts..."
echo ""

# sets environment variables
## git specific configs are set dynamically
read -p "Enter a github personal access token: " TOKEN
export URL=$(git config --get remote.origin.url)
export EMAIL=$(git config --get user.email)


# creates gcp project to use for example
echo "Creating a GCP Project from /terraform-resources/gcp_project.tf"
echo ""
terraform init
sleep 5
terraform apply -auto-approve
sleep 5
export CLUSTER_NAME="gitlab"
export PROJECT=$(cat terraform.tfstate|jq -r '.outputs.project.value')

basename=$(basename $URL)
re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
if [[ $URL =~ $re ]]; then    
    USERNAME=${BASH_REMATCH[4]}
    REPO=${BASH_REMATCH[5]}
fi
echo ""
echo "Git is configured for $USERNAME on the $REPO repository."
echo ""

## sets k8s cluster name and gcp specific variables
#read -p "Enter a k8s cluster name: " NAME

# k8s cluster creation/management
## creates gke cluster in current DEVSHELL gcp project

gcloud container clusters get-credentials $CLUSTER_NAME --zone us-central1 --project $PROJECT

## sets current gcp user as cluster admin 
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole cluster-admin \
--user $(gcloud config get-value account)

## creates the flux namespace and generates an ssh key
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add fluxcd https://charts.fluxcd.io
kubectl create namespace flux

## creates the ssh key used for a deploy key on the repo and then creates a related k8s secret
ssh-keygen -t rsa -N '' -f ./id_rsa -C flux-ssh <<< y
kubectl create secret generic flux-ssh --from-file=identity=./id_rsa -n flux

## adds the deploy key created above to the github repo
curl -s \
-X POST \
-H "Authorization: token ${TOKEN}" \
"Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/${USERNAME}/${REPO}/keys" \
-d "{\"key\":\"$(cat ./id_rsa.pub)\"}"

# installs helm-operator to manage helmreleases
helm upgrade --install helm-operator --version 1.0.2 \
fluxcd/helm-operator \
 -f ./flux/helmOperator.yaml \
 -n flux

# installs flux
sed "s/USERNAME/$USERNAME/g; s/EMAIL/$EMAIL/g; s/REPO/$REPO/g" ./templates/flux.yaml.tpl > "./flux/flux.yaml" 
helm upgrade --install flux \
fluxcd/flux --version 1.3.0 \
-f "./flux/flux.yaml" \
-n flux


# cleanup
rm id_rsa*

echo ""
echo "Run ./grafana-as-code/setup-grafana-executables.sh to setup grafana dashboards and notifiers as code executables"
echo ""