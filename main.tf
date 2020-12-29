# installs gke cluster and gitlab
module "mac-ecosystem" {
  source                = "./mac-ecosystem"
  domain                = ""
  gitlab_runner_install = "false"
  project_id            = var.project_id
  cluster_name          = var.cluster_name
  certmanager_email     = var.certmanager_email
  username              = var.username
  repo                  = var.repo
  github_token          = var.github_token
  gke_machine_type      = "e2-standard-4"
}