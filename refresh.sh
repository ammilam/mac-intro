#! /bin/bash
#! /bin/bash

REGION=$(cat terraform.tfstate|jq -r '.outputs.location.value')
REPO=$(cat terraform.tfstate|jq -r '.outputs.repo.value')
TOKEN=$(cat token)
USERNAME=$(cat terraform.tfstate|jq -r '.outputs.username.value')
EMAIL=$(cat terraform.tfstate|jq -r '.outputs.email.value')
NAME=$(cat terraform.tfstate|jq -r '.outputs.cluster_name.value')
PROJECT=$(cat terraform.tfstate|jq -r '.outputs.project_id.value')
terraform plan -var "repo=${REPO}" -var "github_token=${TOKEN}" -var "username=${USERNAME}" -var "email_address=${EMAIL}" -var "cluster_name=${NAME}" -var "project_id=${PROJECT}"
