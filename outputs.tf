output "region" {
  value = var.region
}

output "suffix" {
  value = module.mac-ecosystem.suffix
}
output "gitlab_address" {
  value       = module.mac-ecosystem.gitlab_address
  description = "IP address where you can connect to your GitLab instance"
}

output "chart_name" {
  value = module.mac-ecosystem.chart_name
}
output "gitlab_url" {
  value       = module.mac-ecosystem.gitlab_url
  description = "URL where you can access your GitLab instance"
}

output "cluster_name" {
  value       = module.mac-ecosystem.cluster_name
  description = "Name of the GKE cluster that GitLab is deployed in."
}

output "cluster_location" {
  value       = module.mac-ecosystem.location
  description = "Location of the GKE cluster that GitLab is deployed in."
}

output "cluster_ca_certificate" {
  value       = module.mac-ecosystem.cluster_ca_certificate
  description = "CA Certificate for the GKE cluster that GitLab is deployed in."
}

output "host" {
  value       = module.mac-ecosystem.host
  description = "Host for the GKE cluster that GitLab is deployed in."
}

output "token" {
  value       = module.mac-ecosystem.token
  description = "Token for the GKE cluster that GitLab is deployed in."
}

output "root_password_instructions" {
  value = module.mac-ecosystem.root_password_instructions
}

output "grafana_address" {
  value = "http://${module.mac-ecosystem.nginx_address}"
}

output "location" {
  value = module.mac-ecosystem.location
}

output "service_account_file" {
  value = local.service_account_file
}