provider "google" {
  project     = var.project_id
  credentials = data.local_file.credentials.content
}

provider "google-beta" {
  project     = var.project_id
  credentials = data.local_file.credentials.content
}


data "local_file" "credentials" {
  filename = "${path.module}/${var.google_credentials}"
}

provider "github" {
  token = var.github_token
  owner = var.username
}


locals {
  service_account_file = var.google_credentials
}

# installs gke cluster and gitlab
module "mac-ecosystem" {
  source                = "./mac-ecosystem"
  domain                = ""
  gitlab_runner_install = "false"
  project_id            = var.project_id
  cluster_name          = var.cluster_name
  email_address         = var.email_address
  username              = var.username
  repo                  = var.repo
  github_token          = var.github_token
  gke_machine_type      = "e2-standard-4"
  google_credentials    = var.google_credentials
}

######################
### GCP Monitoring ###
######################
module "monitoring" {
  source                = "./mac-ecosystem/monitoring"
  username              = var.username
  email_address         = var.email_address
  gke_project_id        = var.project_id
  monitoring_project_id = var.project_id
}