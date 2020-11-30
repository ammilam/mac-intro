
#! /bin/bash
helm delete gitlab
for i in $(kubectl get secrets -o json|jq -r '.items[].metadata.name'); do kubectl delete secret $i; done
for i in $(kubectl get pvc -o json|jq -r '.items[].metadata.name'); do kubectl delete pvc $i; done
for i in $(kubectl get job -o json|jq -r '.items[].metadata.name'); do kubectl delete job $i; done
./setup.sh
