##
# Install Flux
##
# 0 = Environment
##

# if [ "$#" -ne 1 ]; then
#   echo "Usage: ./installHelmOperator den3sbx"
#   exit 1
# fi

# # set vars
# ENVIRONMENT=$1

# Helm install flux
helm upgrade --install helm-operator --version 1.0.2 \
fluxcd/helm-operator \
 -f ./flux/helmOperator.yaml \
 -n flux
