#! /bin/bash

# sets environment variables

## git specific configs are set dynamically
URL=$(git config --get remote.origin.url)
basename=$(basename $URL)
re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
if [[ $URL =~ $re ]]; then    
    USERNAME=${BASH_REMATCH[4]}
    REPO=${BASH_REMATCH[5]}
fi
echo ""
echo "git is configured for $USERNAME on the $REPO repository."
echo ""

## sets k8s cluster name and gcp specific variables
read -p "Enter a k8s cluster name: " NAME
echo ""
read -p "Enter a zone [us-west1/us-east1/us-central1]: " ZONE
echo ""
if [[ -z $ZONE ]]
then
    export ZONE="us-central1"
fi
echo "gcp zone set to $ZONE"
echo ""
export REGION="${ZONE}-c"

# k8s cluster creation/management

## creates gke cluster in current DEVSHELL gcp project
gcloud container --project $DEVSHELL_PROJECT_ID clusters create $NAME --region $REGION

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
-H "Authorization: token $(cat token)" \
"Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/$USERNAME/$REPO/keys" \
-d "{\"key\":\"$(cat ./id_rsa.pub)\"}"

## installs flux and helm operator that will kick off and manage the terraria server deployment
./flux/installFlux.sh
./flux/installHelmOperator.sh


# cleanup
rm id_rsa*
