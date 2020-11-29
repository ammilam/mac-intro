module "gitlab-gke" {
  source                = "./gitlab-gke-module"
  domain                = ""
  gitlab_runner_install = "true"
  project_id            = var.project_id
  cluster_name          = var.cluster_name
  certmanager_email     = var.certmanager_email
}