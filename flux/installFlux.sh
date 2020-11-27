##
# Install Flux
##
# 0 = Environment
##

# Helm install flux
helm upgrade --install flux \
fluxcd/flux --version 1.3.0 \
-f ./flux.yaml \
-n flux
