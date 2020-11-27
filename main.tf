provider "google" {
project_id = google_project.mac_example.project_id
}

provider "google-beta" {
}


resource "random_id" "suffix" {
  byte_length = 2
}


# creates a project in GCP
resource "google_project" "mac_project" {
  project_id      = "mac-example-${random_id.suffix.hex}"
  billing_account = data.google_billing_account.acct.id
  name            = "MaC Project ${random_id.suffix.hex}"
}

data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

## Enable google apis for projects
resource "google_project_service" "mac_example" {
  for_each = toset([
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",
    "cloudapis.googleapis.com",
    "container.googleapis.com"

  ])
  project                    = google_project.mac_project.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}


output "project_id" {
  value = google_project.mac_project.project_id
}
module "gitlab" {
  source            = "./terraform-resources/gitlab"
  project_id        = google_project.mac_project.project_id
  cluster_name      = "example-cluster"
  certmanager_email = "fake@example.com"
}

output "project" {
  value = google_project.mac_project.project_id
}