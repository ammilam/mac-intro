#! /bin/bash
# Author: Andrew Milam

# this sets up the dash-gen-configmap.sh executable that gets grafana dashboards created in the gui and generates flux controlled k8s configmaps for the dashboards
export IP=$(kubectl get svc/prometheus-operator-grafana -n monitoring -o json|jq -r '.status.loadBalancer.ingress[].ip')
sed "s/IP/$IP/g" ../templates/dash-configmap.sh.tpl > ./dashboards/dash-gen-configmap.sh| chmod +x ./dashboards/dash-gen-configmap.sh
echo "executable created ./dashboards/dash-configmap.sh"

# sets up the notifiers-gen-configmap.sh executable that gets grafana notifiers created in the gui and generates flux controlled configmap
sed "s/IP/$IP/g" ../templates/notifiers.sh.tpl > ./notifiers/notifiers-gen-configmap.sh| chmod +x ./dashboards/notifiers-gen-configmap.sh
echo "executable created ./dashboards/dash-configmap.sh"

