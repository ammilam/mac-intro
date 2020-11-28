
provider "google" {
  version = "~> 3.39.0"
}

provider "google-beta" {
  version = "~> 3.39.0"
}

module "gke-gitlab" {
  source            = "git::github.com/ammilam/terraform-google-gke-gitlab"
  project_id        = "${var.project_id}"
  certmanager_email = "no-reply@${var.project_id}.example.com"
  cluster_name      = "${var.cluster_name}"
  gitlab_db_name = "${var.cluster_name}-db"
  gitlab_db_random_prefix = true
}

output "cluster_name" {
    value = module.gke-gitlab.cluster_name
}

output "gitlab_url" {
  value = "${module.gke-gitlab.gitlab_url}"
}
