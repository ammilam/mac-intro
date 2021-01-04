#! /bin/bash
# this script is intended to clean up the resources created by the setup.sh

#####################
### Set Variables ###
#####################
REGION=$(terraform output region)
REPO=$(terraform output repo)
TOKEN=$(cat token)
USERNAME=$(terraform output username)
SA_NAME=account.json
EMAIL=$(terraform output email)
NAME=$(terraform output cluster_name)
PROJECT=$(terraform output project_id)

export GOOGLE_APPLICATION_CREDENTIALS=./$SA_NAME

terraform destroy -var "google_credentials=${SA_NAME}" -var "repo=${REPO}" -var "github_token=${TOKEN}" -var "username=${USERNAME}" -var "email_address=${EMAIL}" -var "cluster_name=${NAME}" -var "project_id=${PROJECT}" -auto-approve

gcloud compute disks list --format=json|grep $NAME|
jq --raw-output '.[] | "\(.name)|\(.zone)"' $PDB_FILE|
while IFS="|" read -r name zone; do
echo name=$name zone=$(echo $zone|awk '{print $NF}' FS=/)
gcloud compute disks delete $name --zone=$zone
done

read -p 'Do you want to delete the Service Account json? ' p
if [[ $p == 'y' ]]
then
    rm ./$SA_NAME
fi
if [[ $p == 'n' ]]
then
    exit 1
fi