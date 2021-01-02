
provider "google" {
  project     = var.project_id
  credentials = "${file("${path.module}/${var.google_credentials}")}"
}

locals {
  service_account_file = var.google_credentials
}

module "project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 9.0"
  disable_services_on_destroy = "false"
  project_id                  = var.project_id
  activate_apis = [
    "iam.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "redis.googleapis.com",
    "monitoring.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}

# installs gke cluster and gitlab
module "mac-ecosystem" {
  source                = "./mac-ecosystem"
  domain                = ""
  gitlab_runner_install = "false"
  project_id            = module.project_services.project_id
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
  monitoring_project_id = module.project_services.project_id
}
