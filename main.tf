
provider "google" {
}

provider "google-beta" {
}

resource "random_id" "suffix" {
  byte_length = 2
}

module "gke-gitlab" {
  source                = "git::https://github.com/ammilam/terraform-google-gke-gitlab.git"
  project_id            = "${var.project_id}"
  certmanager_email     = "no-reply@${var.project_id}.example.com"
  cluster_name          = "${var.cluster_name}"
  gitlab_db_name        = "${var.cluster_name}-${random_id.suffix.hex}"
  helm_chart_version    = "4.6.0"
  gitlab_runner_install = true
  region                = "us-east1"
}

output "location" {
    value = "${module.gke-gitlab.region}"
}