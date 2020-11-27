provider "google" {
 region  = "us-central1"
 zone    = "us-central1-c"
}
resource "random_id" "suffix" {
  byte_length = 2
}
data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

# creates a project in GCP
resource "google_project" "mac_project" {
  name                = "MaC Project"
  project_id          = "mac-example-${random_id.suffix.hex}"
  billing_account = data.google_billing_account.acct.id
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
output "project" {
    value = google_project.mac_project.project_id
}