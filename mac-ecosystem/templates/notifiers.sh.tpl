#! /bin/bash -e
# Author - Andrew Milam
# This procedurally generates kuberentes resource definitions from notifieres in grafana to be checked in as code and maintained by flux
# Enabled monitoring as code

API_KEY=$1
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


RED=$(tput setaf 1) # Red
GRN=$(tput setaf 2) # Green
YLW=$(tput setaf 3) # Yellow
BLU=$(tput setaf 4) # Blue - Too dark for black background
PUR=$(tput setaf 5) # Purple
CYN=$(tput setaf 6) # Cyan
WHT=$(tput setaf 7) # White
RST=$(tput sgr0) # Text reset.
BLD=$(tput bold) # Bold

which yq 2>&1 >/dev/null || (echo "Error, yq executable is required" && exit 1) || exit 1
which jq 2>&1 >/dev/null || (echo "Error, jq executable is required" && exit 1) || exit 1

usage() {
   cat <<USAGE
${BLD}At runtime, you must specify a $ENV Grafana Admin API_KEY
Example:
./$SCRIPT_NAME ${GRN}eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk${RST}
To generate an Admin API_KEY go to IP/org/apikeys
USAGE
}


[[ -z "$1" || "$1" =~ ^(-h|--help)$ ]] && usage && exit 1


cu(){
curl -H "Authorization: Bearer ${API_KEY}" "IP/api/alert-notifications"
}


cfgmap() {
   cu |jq 'del(.[].created, .[].updated)|{"notifiers": .}'| yq r - --prettyPrint > notifiers.yaml
   kubectl create configmap notifiers-configmap --namespace=cwow-prometheus --from-file=./notifiers.yaml --dry-run=true -o yaml|grep -v creationTimestamp > "provisioned-notifiers.yaml"
   echo "Generated: provisioned-notifiers.yaml"
   rm notifiers.yaml
   exit 1
}

list() {
    echo ""
    read -p "Do want to you list current Grafana alert channels in ${ENV}?[y/n] "  P1
}

list

if [[ $P1 == "y" ]]
then
    NAME=$(cu|jq -r '.[].name')
    echo ""
    echo "These are the current alert channels: "
    echo ""
    printf "${NAME}\n  \n"
    read -p 'Do you want to make a configmap for these alert channels?[y/n] ' P2
fi

if [[ $P2 == "y" ]]
then
    cfgmap
fi

if [[  $P1 == "n" || $P2 == "n" ]]
then exit 1
fi

if [[ ($P1 != y||n) ]]
then
    echo "You did not enter a valid option."
fi

if [[ ($P2 != y||n) ]]
then
    echo "You did not enter a valid option."
fi