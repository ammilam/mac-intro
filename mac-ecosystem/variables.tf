variable "project_id" {
  description = "GCP Project to deploy resources"
}

variable "github_token" {
  type        = string
  description = "Github personal access token"
}
variable "domain" {
  description = "Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at gitlab.mydomain.com)"
  default     = ""
}

variable "flux_version" {
  default = "1.6.0"
}

variable "helm_operator_version" {
  default = "1.1.0"
}
variable "repo" {
  type        = string
  description = "Github repo connected to flux"
}
variable "username" {
  type        = string
  description = "Github username"
}
variable "email_address" {
  description = "Email used to retrieve SSL certificates from Let's Encrypt"
}

variable "gke_version" {
  description = "Version of GKE to use for the GitLab cluster"
  default     = "1.16"
}

variable "cluster_name" {
  type = string
}

variable "gke_machine_type" {
  description = "Machine type used for the node-pool"
  default     = "n1-standard-4"
}

variable "gitlab_db_name" {
  description = "Instance name for the GitLab Postgres database."
  default     = "gitlab-db"
}

variable "gitlab_db_random_prefix" {
  description = "Sets random suffix at the end of the Cloud SQL instance name."
  default     = false
}

variable "gitlab_db_password" {
  description = "Password for the GitLab Postgres user"
  default     = ""
}

variable "gitlab_address_name" {
  description = "Name of the address to use for GitLab ingress"
  default     = ""
}

variable "grafana_address_name" {
  description = "Name of the address to use for GitLab ingress"
  default     = "grafana"
}
variable "gitlab_runner_install" {
  description = "Choose whether to install the gitlab runner in the cluster"
  default     = false
}

variable "region" {
  default     = "us-central1"
  description = "GCP region to deploy resources to"
}

variable "gitlab_nodes_subnet_cidr" {
  default     = "10.0.0.0/16"
  description = "Cidr range to use for gitlab GKE nodes subnet"
}

variable "gitlab_pods_subnet_cidr" {
  default     = "10.3.0.0/16"
  description = "Cidr range to use for gitlab GKE pods subnet"
}

variable "gitlab_services_subnet_cidr" {
  default     = "10.2.0.0/16"
  description = "Cidr range to use for gitlab GKE services subnet"
}
variable "helm_chart_version" {
  type        = string
  default     = "4.6.0"
  description = "Helm chart version to install during deployment"
}

variable "google_credentials" {
  type = string
}