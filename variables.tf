variable "project_id" {
  type = string
}
variable "certmanager_email" {
  description = "Email used to retrieve SSL certificates from Let's Encrypt"
  type        = string
}

variable "cluster_name" {
  type = string
}