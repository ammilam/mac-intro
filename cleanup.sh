
#! /bin/bash
REGION=$(cat terraform.tfstate|jq -r '.outputs.location.value')
REPO=$(cat terraform.tfstate|jq -r '.outputs.repo.value')
TOKEN=$(cat terraform.tfstate|jq -r '.outputs.github_token.value')
USERNAME=$(cat terraform.tfstate|jq -r '.outputs.username.value')
EMAIL=$(cat terraform.tfstate|jq -r '.outputs.email.value')
NAME=$(cat terraform.tfstate|jq -r '.outputs.cluster_name.value')
PROJECT=$(cat terraform.tfstate|jq -r '.outputs.project_id.value')
terraform destroy -var "repo=${REPO}" -var "github_token=${TOKEN}" -var "username=${USERNAME}" -var "certmanager_email=${EMAIL}" -var "cluster_name=${NAME}" -var "project_id=${PROJECT}" -auto-approve
