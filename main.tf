
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
