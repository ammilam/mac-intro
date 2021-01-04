# WIP - Monitoring as Code (MaC) & k8s Gitops Implementation

## Purpose
This repo attempts to lay a general framework to play with a MaC implementation, as well as a kubernetes Gitops implementation, and is broken down into the following parts...

- GKE (Google Kubernetes Engine) Cluster Creation by Terraform
- Installation of Gitlab in GKE using  the [terraform-google-gke-gitlab](https://github.com/terraform-google-modules/terraform-google-gke-gitlab) module
- Installation of flux/helm-operator to implement k8s Gitops
- Flux automated deployment of prometheus-stack (prometheus/alertmanager/grafana) and other k8s resources
- Grafana Dashboarding/Alerts/Notifiers as Code Implementation
- GCP Alerts/Monitoring Implementation
- WIP -> GCP Dashboard Auto Provisioning


## But really? Why cloud monitoring as code?
Cloud resources are meant to be expendable, being spun up/down at will (pets vs cattle) while also being provisioned with speed and precision. This is achieved in an organizationally standardized and repeatable manner as code while also being made more widely available to more teams through merge requests with governance/approval processes.
In the end, managing infrastructure as code allows cloud resources to be dynamic, follow an enterprise standard, have governance at all levels by SMEs, have versioning, and be better prepared for a disaster.


## Before You Begin
In order to install get going with this example implementation, you must have access to a GCP Project, and either [Cloud Shell](https://cloud.google.com/shell) or [CloudSDK](https://cloud.google.com/sdk/docs/quickstart)

- This requires that you have a google cloud project to work with. Google offers a free tier of GCP (one per each Gmail account) that equates to $300 of free resources. Signing up for this will require a credit/debit card for account creation and managment purposes, that being said... this will never charge your card. Any trial started is automatically deactivated when you run out of the $300 free credit -> [link to sign up for gcp trial](https://cloud.google.com/free)

- Since this uses GCP as the cloud provider, you must use [Cloud Shell](https://cloud.google.com/shell/docs) to run these commands (reccomended), or have Google CloudSDK installed locally -> [quickstart link](https://cloud.google.com/sdk/docs/quickstart)

Note: I recommend running this through Cloud Shell from within GCP as mentioned above. If you absolutely must run this locally, you must have [helm](https://helm.sh/docs/intro/install/) and [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed and access to a linux os/subsystem.

## Getting Started
### Setting Up GKE / Gitlab / Flux / Helm Operator

1. Fork and clone down this repository
2. Get a github [personal access token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) with the `repo` scope selected
3. Create a new gcp project - [Documentation](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
4. Enable the Monitoring Workspace by doing the following
    1. Go to the [Cloud Console](https://console.cloud.google.com/)
    2. In the toolbar, select your Google Cloud project by using the project selector.
    3. In the Cloud Console navigation menu, click Monitoring.

        `note: At this time Google doesnt offer a way to easily enable the montioring workspace using terraform or the api, so this part is manual)`
5. Execute the following in the repo cloned locally

```bash
# configure git user variables (enter your name and the account associated with github)
git config --global user.email "EMAIL"   # enter your github email here
git config --global user.name "USERNAME" # enter your github username here

# setup GKE cluster, Gitlab, flux/helm-operator, and prometheus stack
./setup.sh

# terminal will prompt for a github personal access token.
Enter a github personal access token: # enter your github personal access token here
```

This will create a GKE cluster, deploy Gitlab, and hook up an intentionally broken [flux](https://fluxcd.io/) with corresponding gcp custom logging metric and alert policy that contains instructions on how to fix the "problem". Once operational, flux will hook up to this forked Github repo and deploy any kubernetes resource definitons or helmreleses contained under `/mac-ecosystem/releases`. This is intended to give people insight into what a montioring as code ecosystem looks like.

#### Resources Deployed By Flux
- example hello world app
- cert-manager
- kube-prometheus-stack

**Please Note:** you will be expected to provide a [Github Persional Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) - so have one handy.

## Maintaining Resources
### Altering Gitlab Configs
Gitlab is deployed by helm chart during the setup process above. Configuration changes can be made to the values.yaml file under `/mac-ecosystem/templates/values-files/gitlab-values.yaml.tpl`. For information on supported settings refer to this [documentation](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml)

Once changes have been made to `/mac-ecosystem/templates/values-files/gitlab-values.yaml.tpl`, sync the changes by re-running:
```bash
# this will sync settings to the cluster, including Gitlab changes
./setup.sh
```


### Deploying New Kubernetes  Resources / HelmRelease Using Flux & Helm-Operator
In order to update/create a new [HelmRelease](https://docs.fluxcd.io/projects/helm-operator/en/1.0.0-rc9/references/helmrelease-custom-resource.html), or deploy Kubernetes resources (namespace/deployment/pod/etc), a resource definition will need to be placed under the `/mac-ecosystem/releases` directory at the root of this repository. Once merged to main/master, flux will automatically sync the changes with the GKE cluster on a 1 minute sync loop.

___







Author: [Andrew Milam](https://www.linkedin.com/in/andrewmilam/)
