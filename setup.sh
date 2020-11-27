#! /bin/bash

# sets environment variables

## gcp project variable
PROJECT=$(gcloud config list --format json|jq -r '.core.project')
## git specific configs are set dynamically
read -p "enter a github personal access token: " TOKEN
URL=$(git config --get remote.origin.url)
EMAIL=$(git config --get user.email)

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


# k8s cluster creation/management
## creates gke cluster in current DEVSHELL gcp project
gcloud container --project $PROJECT clusters create $NAME --region "${ZONE}-c"

gcloud container clusters get-credentials $NAME --region "${ZONE}-c" --project $PROJECT

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
flux() {
    sed "s/USERNAME/$USERNAME/g; s/EMAIL/$EMAIL/g; s/REPO/$REPO/g" ./flux/flux.yaml.tpl > "./$USERNAME-flux/flux.yaml" 
    helm upgrade --install flux \
    fluxcd/flux --version 1.3.0 \
    -f "./$USERNAME-flux/flux.yaml" \
    -n flux
}
if [[ ! -d "$USERNAME-flux" ]]
then
    mkdir "$USERNAME-flux"
    flux
fi
if [[ "$USERNAME-flux" ]]
then
    sed "s/USERNAME/$USERNAME/g; s/EMAIL/$EMAIL/g; s/REPO/$REPO/g" ./flux/flux.yaml > "./$USERNAME-flux/flux.yaml" 
    flux
fi

# cleanup
rm id_rsa*

# creates executable to be used to generate configmaps from grafana dashboards created in the UI
export IP=$(kubectl get svc/prometheus-operator-grafana -n monitoring -o json|jq -r '.status.loadBalancer.ingress[].ip')
echo "The Grafana Public IP Address Is: $IP"
sed "s/IP/$IP/g" ./grafana-as-code/dashboards/dash-configmap.sh.tpl > ./grafana-as-code/dashboards/dash-configmap.sh| chmod +x ./grafana-as-code/dashboards/dash-configmap.sh