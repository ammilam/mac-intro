#! /bin/bash
# Author: Andrew Milam

# this sets up the dashboards.sh executable that gets grafan dashboards created in the gui and generates flux controlled k8s configmaps for the dashboards
export IP=$(kubectl get svc/prometheus-operator-grafana -n monitoring -o json|jq -r '.status.loadBalancer.ingress[].ip')
sed "s/IP/$IP/g" ../templates/dash-configmap.sh.tpl > ./dashboards/dash-configmap.sh| chmod +x ./dashboards/dash-configmap.sh
echo "executable created ./dashboards/dash-configmap.sh"

