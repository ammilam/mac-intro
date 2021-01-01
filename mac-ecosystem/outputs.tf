output "region" {
  value = var.region
}

output "suffix" {
  value = random_id.suffix.hex
}
output "gitlab_address" {
  value       = local.gitlab_address
  description = "IP address where you can connect to your GitLab instance"
}

output "chart_name" {
  value = helm_release.gitlab.name
}
output "gitlab_url" {
  value       = "https://gitlab.${local.domain}"
  description = "URL where you can access your GitLab instance"
}

output "cluster_name" {
  value       = module.gke.name
  description = "Name of the GKE cluster that GitLab is deployed in."
}

output "cluster_location" {
  value       = module.gke.location
  description = "Location of the GKE cluster that GitLab is deployed in."
}

output "cluster_ca_certificate" {
  value       = module.gke_auth.cluster_ca_certificate
  description = "CA Certificate for the GKE cluster that GitLab is deployed in."
}

output "host" {
  value       = module.gke_auth.host
  description = "Host for the GKE cluster that GitLab is deployed in."
}

output "token" {
  value       = module.gke_auth.token
  description = "Token for the GKE cluster that GitLab is deployed in."
}

output "root_password_instructions" {
  value = <<EOF
  Run the following commands to get the root user password:
  gcloud container clusters get-credentials gitlab --zone ${var.region} --project ${var.project_id}
  kubectl get secret gitlab-gitlab-initial-root-password -o go-template='{{ .data.password }}' | base64 -d && echo
  EOF

  description = "Instructions for getting the root user's password for initial setup"
}

output "location" {
  value = module.gke.location
}

output "grafana_address" {
  value = data.google_compute_address.grafana.address
}

output "project_id" {
  value = var.project_id
}

output "username" {
  value = var.username
}

output "email_address" {
  value = var.email_address
}
