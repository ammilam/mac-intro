provider "github" {
  token = var.github_token
  owner = var.username
}

# installs gke cluster and gitlab
module "gitlab-gke" {
  source                = "./gitlab-gke-module"
  domain                = ""
  gitlab_runner_install = "false"
  project_id            = var.project_id
  cluster_name          = var.cluster_name
  certmanager_email     = var.certmanager_email
}

# creates flux values.yaml file
data "template_file" "flux_yaml" {
  template = "${file("./templates/flux-values.yaml.tpl")}"

  vars = {
    EMAIL    = var.certmanager_email
    USERNAME = var.username
    REPO     = var.repo
  }
}

# creates the flux values.yaml file from the redered data above
resource "local_file" "flux_yaml" {
  content  = data.template_file.flux_yaml.rendered
  filename = "./flux-install/flux-values.yaml"
}

# creates key for flux & github 
resource "tls_private_key" "mac_deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# creates public key in github
resource "github_repository_deploy_key" "mac_intro_repo" {
  title      = "Repository test key"
  repository = "mac-intro"
  key        = tls_private_key.mac_deploy_key.public_key_openssh
  read_only  = "false"
}

# creates kubernetes secret for flux to pull changes from github and sync with gke
resource "kubernetes_secret" "flux_ssh" {
  metadata {
    name      = "flux-ssh"
    namespace = "flux"
  }
  data = {
    "identity" = "${tls_private_key.mac_deploy_key.private_key_pem}"
  }
  depends_on = [tls_private_key.mac_deploy_key]
}


resource "helm_release" "helm_operator" {
  name         = "helm-operator"
  namespace    = "flux"
  repository   = "https://charts.fluxcd.io"
  chart        = "helm-operator"
  version      = "1.2.0"
  timeout      = "1200"
  wait         = false
  force_update = "true"

  values = [
    "${file("./flux-install/helmOperator.yaml")}",
  ]
  depends_on = [
    kubernetes_secret.flux_ssh
  ]
}
resource "helm_release" "fluxcd" {
  name         = "flux"
  repository   = "https://charts.fluxcd.io"
  namespace    = "flux"
  chart        = "flux"
  version      = "1.6.0"
  timeout      = 1200
  wait         = false
  force_update = "true"

  values = [
    data.template_file.flux_yaml.rendered
  ]
  depends_on = [
    kubernetes_secret.flux_ssh, local_file.flux_yaml, helm_release.helm_operator
  ]
}