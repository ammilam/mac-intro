## WIP - Monitoring as Code (MaC) Implementation

### Purpose
This repo attempts to lay a general framework to play with a MaC Implementation and is broken down into the following parts...

- GKE Cluster Creation
- Flux CI/CD Installation -> installs various k8s resources
- Grafana Dashboarding/Alerts/Notifiers as Code Implementation
- GCP Alerts/Monitoring Implementation
- GCP Dashboard Auto Provisioning

### Usage
To get started, simply fork this repo and clone locally and execute the following:

```bash
./setup.sh
```

This will create a GKE cluster and hook up flux CI/CD to the forked Github repo and deploy the releses contained under `/releases`

At this portion of the install, you will be expected to provide a [Github Persional Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) - so have one handy.






#####
Author: [Andrew Milam](https://www.linkedin.com/in/andrewmilam/)
###