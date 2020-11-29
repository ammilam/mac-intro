output "cluster_name" {
  value = module.gke-gitlab.cluster_name
}

output "gitlab_url" {
  value = "${module.gke-gitlab.gitlab_url}"
}

output "chart_name" {
  value = module.gke-gitlab.chart_name
}

output "suffix" {
  value = module.gke-gitlab.suffix
}