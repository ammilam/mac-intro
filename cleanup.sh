#! /bin/bash
# this script is intended to clean up the resources created by the setup.sh
REGION=$(cat terraform.tfstate|jq -r '.outputs.location.value')
REPO=$(cat terraform.tfstate|jq -r '.outputs.repo.value')
TOKEN=$(cat token)
USERNAME=$(cat terraform.tfstate|jq -r '.outputs.username.value')
SA_NAME=$(cat terraform.tfstate|jq -r '.outputs.google_credentials.value')
EMAIL=$(cat terraform.tfstate|jq -r '.outputs.email.value')
NAME=$(cat terraform.tfstate|jq -r '.outputs.cluster_name.value')
PROJECT=$(cat terraform.tfstate|jq -r '.outputs.project_id.value')
terraform destroy -var "repo=${REPO}" -var "github_token=${TOKEN}" -var "username=${USERNAME}" -var "email_address=${EMAIL}" -var "cluster_name=${NAME}" -var "project_id=${PROJECT}" -auto-approve
#for d in $(gcloud compute disks list|awk 'NR>1 {print $1 $2}'); do gcloud compute disks delete $1 --zone $2 ; done
rm $SA_NAME