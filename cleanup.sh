
#! /bin/bash
helm delete gitlab
for i in $(kubectl get secrets -o json|jq -r '.items[].metadata.name'); do kubectl delete secret $i; done
./setup.sh
