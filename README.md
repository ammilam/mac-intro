## Monitoring as Code (MaC) Implementation
This repo attempts to lay a general framework to play with a MaC Implementation and is broken down into the following parts...

- GKE Cluster Creation
- Flux CI/CD Installation -> installs various k8s resources
- Grafana Dashboarding/Alerts/Notifiers as Code Implementation
- GCP Alerts/Monitoring Implementation
- GCP Dashboard Auto Provisioning

### To get started...

Simply fork this repo and clone locally and execute the following:

`./setup.sh`

You will be expected to provide a [Github Persional Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) - so have one handy.