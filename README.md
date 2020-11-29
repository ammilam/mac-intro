## WIP - Monitoring as Code (MaC) & k8s Gitops Implementation

## Purpose
This repo attempts to lay a general framework to play with a MaC implementation, as well as a kubernetes Gitops implementation, and is broken down into the following parts...

- GKE (Google Kubernetes Engine) Cluster Creation by Terraform
- Installation of Gitlab in GKE using  the [terraform-google-gke-gitlab](https://github.com/terraform-google-modules/terraform-google-gke-gitlab) module
- Installation of flux/helm-operator to implement k8s Gitops
- Flux automated deployment of prometheus-stack (prometheus/alertmanager/grafana) and other k8s resources
- Grafana Dashboarding/Alerts/Notifiers as Code Implementation
- WIP -> GCP Alerts/Monitoring Implementation
- WIP -> GCP Dashboard Auto Provisioning

## But really? Why cloud monitoring as code?
Cloud resources are meant to be expendable, being spun up/down at will (pets vs cattle) while also being provisioned with speed and precision. This is achieved in an organizationally standardized and repeatable manner as code while also being made more widely available to more teams through merge requests with governance/approval processes.
In the end, managing infrastructure as code allows cloud resources to be dynamic, follow an enterprise standard, have governance at all levels by SMEs, have versioning, and be better prepared for a disaster.

## Before You Begin
In order to install get going with this example implementation, you must have access to a GCP Project, and either [Cloud Shell](https://cloud.google.com/shell) or [CloudSDK](https://cloud.google.com/sdk/docs/quickstart)

- This requires that you a google cloud project to work with. Google offers a free tier of GCP (one per each Gmail account) that equates to $300 of free resources -> [link to sign up for gcp trial](https://cloud.google.com/free)

- Since this uses GCP as the cloud provider, you must have Google CloudSDK installed -> [quickstart link](https://cloud.google.com/sdk/docs/quickstart)


## Getting Started
### Setting Up GKE / Gitlab / Flux / Helm Operator

To kick this off  simply fork this repo, clone locally, and execute the following:

```bash
# configure git user variables
git config --global user.email "EMAIL"
git config --global user.name "USERNAME"

# setup GKE cluster, Gitlab, flux/helm-operator, and prometheus stack
./setup.sh

# terminal will prompt for a github personal access token.
Enter a github personal access token:
```

This will create a GKE cluster, deploy Gitlab, and hook up [flux](https://fluxcd.io/) to the forked Github repo and deploy the releses contained under `/releases`

*Please Note*: you will be expected to provide a [Github Persional Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) - so have one handy.

#### Managing Flux Post Install
Flux automatically syncs k8s resources and helm chart by means of helm-operator & helmrelease definitons.

To manage flux post installation, edit `flux.yaml` located under `/flux` with new configurations. Refer to this [documentation](https://github.com/fluxcd/flux/blob/master/chart/flux/values.yaml) for flux values.yaml config settings.
```bash
# bash script that simply does an update/install of the flux chart
./flux/installFlux.sh

```

#### Managing Helm-Operator Post Install
To manage helm-operator post installation, edit `helmOperator.yaml` located under `/flux` with new configurations. Refer to this [documentation](https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/values.yaml) for helm-operator values.yaml config settings.
```bash
# bash script that simply does an update/install of the helm-operator chart
./flux/installHelmOperator.sh

```









#####
Author: [Andrew Milam](https://www.linkedin.com/in/andrewmilam/)
###
