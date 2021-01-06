locals {
  gitlab_db_name = "${var.gitlab_db_name}-${random_id.suffix.hex}"
}



module "gke_auth" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "~> 9.1"

  project_id   = module.project_services.project_id
  cluster_name = module.gke.name
  location     = module.gke.location
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
    host                   = module.gke_auth.host
    token                  = module.gke_auth.token
  }
}

resource "random_id" "suffix" {
  byte_length = 2
}

provider "kubernetes" {
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  host                   = module.gke_auth.host
  token                  = module.gke_auth.token
}

resource "google_project_service" "project" {
  project            = var.project_id
  disable_on_destroy = "false"
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",

  ])
  service = each.value
}

# project api enablement
module "project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 9.0"
  disable_services_on_destroy = "false"
  project_id                  = var.project_id

  activate_apis = [
    "iam.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "redis.googleapis.com",
    "monitoring.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}


// GCS Service Account
resource "google_service_account" "gitlab_gcs" {
  project      = var.project_id
  account_id   = "gitlab-gcs"
  display_name = "GitLab Cloud Storage"
  depends_on   = [module.project_services]
}

resource "google_service_account_key" "gitlab_gcs" {
  service_account_id = google_service_account.gitlab_gcs.name
  depends_on         = [module.project_services]

}

resource "google_project_iam_member" "project" {
  project    = var.project_id
  role       = "roles/storage.admin"
  member     = "serviceAccount:${google_service_account.gitlab_gcs.email}"
  depends_on = [module.project_services]

}

// Networking
resource "google_compute_network" "gitlab" {
  name                    = "gitlab"
  project                 = module.project_services.project_id
  auto_create_subnetworks = false
  depends_on              = [module.project_services]

}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "gitlab"
  ip_cidr_range = var.gitlab_nodes_subnet_cidr
  region        = var.region
  network       = google_compute_network.gitlab.self_link
  depends_on    = [module.project_services]


  secondary_ip_range {
    range_name    = "gitlab-cluster-pod-cidr"
    ip_cidr_range = var.gitlab_pods_subnet_cidr
  }

  secondary_ip_range {
    range_name    = "gitlab-cluster-service-cidr"
    ip_cidr_range = var.gitlab_services_subnet_cidr
  }
}

resource "google_compute_address" "gitlab" {
  name         = "gitlab"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Gitlab Ingress IP"
  depends_on   = [module.project_services, google_compute_address.nginx]
  count        = var.gitlab_address_name == "" ? 1 : 0
}


// Database
resource "google_compute_global_address" "gitlab_sql" {
  provider      = google-beta
  project       = module.project_services.project_id
  name          = "gitlab-sql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = google_compute_network.gitlab.self_link
  address       = "10.1.0.0"
  prefix_length = 16
  depends_on    = [module.project_services]

}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.gitlab.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gitlab_sql.name]
  depends_on              = [module.project_services]
}

# creates nginx external IP
resource "google_compute_address" "nginx" {
  name         = var.nginx_address_name
  project      = module.project_services.project_id
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Nginx Ingress IP"
  depends_on   = [module.project_services]
}


resource "google_sql_database_instance" "gitlab_db" {
  depends_on          = [google_service_networking_connection.private_vpc_connection, module.project_services]
  name                = local.gitlab_db_name
  region              = var.region
  project             = module.project_services.project_id
  database_version    = "POSTGRES_11"
  deletion_protection = "false"


  settings {
    tier            = "db-custom-4-15360"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.gitlab.self_link
    }
  }

}

resource "google_sql_database" "gitlabhq_production" {
  name       = "gitlabhq_production"
  instance   = google_sql_database_instance.gitlab_db.name
  depends_on = [google_sql_user.gitlab, module.project_services]
  project    = module.project_services.project_id
}

resource "random_string" "autogenerated_gitlab_db_password" {
  length  = 16
  special = false
}

resource "google_sql_user" "gitlab" {
  name       = "gitlab"
  instance   = google_sql_database_instance.gitlab_db.name
  depends_on = [module.project_services]
  password   = var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result
}

// Redis
resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = "STANDARD_HA"
  memory_size_gb     = 5
  region             = var.region
  authorized_network = google_compute_network.gitlab.self_link

  depends_on = [module.project_services]

  display_name = "GitLab Redis"
}

// Cloud Storage
resource "google_storage_bucket" "gitlab-backups" {
  name          = "${var.project_id}-gitlab-backups"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "gitlab-uploads" {
  name          = "${var.project_id}-gitlab-uploads"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "gitlab-artifacts" {
  name          = "${var.project_id}-gitlab-artifacts"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "git-lfs" {
  name          = "${var.project_id}-git-lfs"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "gitlab-packages" {
  name          = "${var.project_id}-gitlab-packages"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "gitlab-registry" {
  name          = "${var.project_id}-registry"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "gitlab-pseudo" {
  name          = "${var.project_id}-pseudo"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket" "gitlab-runner-cache" {
  name          = "${var.project_id}-runner-cache"
  force_destroy = true
  location      = var.region
}



// GKE Cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 12.0"

  # Create an implicit dependency on service activation
  project_id = module.project_services.project_id

  name               = var.cluster_name
  region             = var.region
  regional           = true
  kubernetes_version = var.gke_version

  remove_default_node_pool = true
  initial_node_count       = 1

  network           = google_compute_network.gitlab.name
  subnetwork        = google_compute_subnetwork.subnetwork.name
  ip_range_pods     = "gitlab-cluster-pod-cidr"
  ip_range_services = "gitlab-cluster-service-cidr"

  issue_client_certificate = true

  node_pools = [
    {
      name         = var.cluster_name
      autoscaling  = false
      machine_type = var.gke_machine_type
      node_count   = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "kubernetes_storage_class" "pd-ssd" {
  metadata {
    name = "pd-ssd"
  }

  storage_provisioner = "kubernetes.io/gce-pd"

  parameters = {
    type = "pd-ssd"
  }
}

resource "kubernetes_secret" "gitlab_pg" {
  metadata {
    name = "gitlab-pg"
  }

  data = {
    password = "${var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result}"
  }
}

resource "kubernetes_secret" "gitlab_rails_storage" {
  metadata {
    name = "gitlab-rails-storage"
  }

  data = {
    connection = <<EOT
provider: Google
google_project: ${var.project_id}
google_client_email: ${google_service_account.gitlab_gcs.email}
google_json_key_string: '${base64decode(google_service_account_key.gitlab_gcs.private_key)}'
EOT
  }
}

resource "kubernetes_secret" "gitlab_registry_storage" {
  metadata {
    name = "gitlab-registry-storage"
  }

  data = {
    "gcs.json" = <<EOT
${base64decode(google_service_account_key.gitlab_gcs.private_key)}
EOT
    storage    = <<EOT
gcs:
  bucket: ${var.project_id}-registry
  keyfile: /etc/docker/registry/storage/gcs.json
EOT
  }
}


resource "kubernetes_secret" "gitlab_gcs_credentials" {
  metadata {
    name = "google-application-credentials"
  }

  data = {
    gcs-application-credentials-file = base64decode(google_service_account_key.gitlab_gcs.private_key)
  }
}

data "google_compute_address" "gitlab" {
  name   = var.gitlab_address_name
  region = var.region

  # Do not get data if the address is being created as part of the run
  count = var.gitlab_address_name == "" ? 0 : 1
}

locals {
  gitlab_address = var.gitlab_address_name == "" ? google_compute_address.gitlab.0.address : data.google_compute_address.gitlab.0.address
  domain         = var.domain != "" ? var.domain : "${local.gitlab_address}.xip.io"
}

data "template_file" "gitlab_values" {
  template = file("${path.module}/templates/values-files/gitlab-values.yaml.tpl")
  vars = {
    DOMAIN                = local.domain
    INGRESS_IP            = local.gitlab_address
    DB_PRIVATE_IP         = google_sql_database_instance.gitlab_db.private_ip_address
    REDIS_PRIVATE_IP      = google_redis_instance.gitlab.host
    PROJECT_ID            = var.project_id
    CERT_MANAGER_EMAIL    = var.email_address
    GITLAB_RUNNER_INSTALL = var.gitlab_runner_install
  }
}

resource "local_file" "gitlab_yaml" {
  content    = data.template_file.gitlab_values.rendered
  filename   = "${path.module}/values-files/gitlab-values.yaml"
  depends_on = [kubernetes_namespace.flux]
}

resource "time_sleep" "sleep_for_cluster_fix_helm_6361" {
  create_duration  = "300s"
  destroy_duration = "60s"
  depends_on       = [module.gke.endpoint, google_sql_database.gitlabhq_production]
}

resource "helm_release" "gitlab" {
  name         = "gitlab"
  repository   = "https://charts.gitlab.io"
  chart        = "gitlab"
  version      = var.helm_chart_version
  timeout      = "1600"
  wait         = "false"
  force_update = "true"

  values = [data.template_file.gitlab_values.rendered]

  depends_on = [
    google_redis_instance.gitlab,
    google_sql_user.gitlab,
    kubernetes_storage_class.pd-ssd,
    time_sleep.sleep_for_cluster_fix_helm_6361,
  ]
}

data "google_compute_address" "nginx" {
  name       = var.nginx_address_name
  depends_on = [module.project_services]
  region     = var.region
  project    = module.project_services.project_id
}

locals {
  nginx_address = data.google_compute_address.nginx.address
}

data "template_file" "ingress_nginx" {
  template = file("${path.module}/templates/values-files/ingress-nginx.yaml.tpl")
  vars = {
    NGINXIP = local.nginx_address
  }
  depends_on = [
    google_compute_address.nginx
  ]
}
data "template_file" "get_dashboards" {
  template = file("${path.module}/templates/scripts/get-dashboard.sh.tpl")
  vars = {
    NGINXIP = local.nginx_address
  }
  depends_on = [
    google_compute_address.nginx,
    time_sleep.nginx_helm,
    data.template_file.ingress_nginx
  ]
}


# data "template_file" "prom_stack" {
#   template = file("${path.module}/templates/values-files/prom-stack-values.yaml.tpl")
#   vars = {
#     NGINXIP = local.nginx_address
#   }
#   depends_on = [
#     google_compute_address.nginx
#   ]
# }

resource "time_sleep" "nginx_helm" {
  create_duration  = "120s"
  destroy_duration = "10s"
  depends_on = [
    module.gke.endpoint,
    google_compute_address.nginx,
  ]
}

# resource "local_file" "prom_stack_yaml" {
#   content  = data.template_file.ingress_nginx.rendered
#   filename = "${path.module}/values-files/prom-stack-values.yaml"
#   depends_on = [
#     google_compute_address.nginx,
#     time_sleep.nginx_helm
#   ]
# }

# creates a local copy of values.yaml file to reference outside of terraform automation
resource "local_file" "get_dashboards_sh" {
  content    = data.template_file.get_dashboards.rendered
  filename   = "${path.module}/releases/kube-prometheus-stack/dashboards/get-dashboard.sh"
  depends_on = [time_sleep.nginx_helm, data.template_file.ingress_nginx]
}


resource "local_file" "ingress_nginx_yaml" {
  content  = data.template_file.ingress_nginx.rendered
  filename = "${path.module}/values-files/ingress-nginx.yaml"
  depends_on = [
    google_compute_address.nginx,
    data.template_file.ingress_nginx,
    time_sleep.nginx_helm,
    helm_release.helm_operator
  ]
}

# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   namespace  = "cert-manager"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   version    = "1.1.0"

#   values = [
#     "${file("${path.module}/values-files/cert-manager-values.yaml")}"
#   ]
#   depends_on = [
#     kubernetes_namespace.cert_manager,
#     time_sleep.sleep_for_cluster_fix_helm_6361
#   ]
# }

############################
### Helm Operator Config ###
############################
resource "helm_release" "helm_operator" {
  name       = "helm-operator"
  namespace  = "flux"
  repository = "https://charts.fluxcd.io"
  chart      = "helm-operator"
  version    = "1.2.0"

  values = [
    "${file("${path.module}/values-files/helm-operator-values.yaml")}"
  ]
  depends_on = [
    kubernetes_secret.flux_ssh,
    kubernetes_namespace.flux,
    time_sleep.sleep_for_cluster_fix_helm_6361
  ]
}

###################
### Flux Config ###
###################

# creates key for flux & github
resource "tls_private_key" "mac_deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# creates public key in github
resource "github_repository_deploy_key" "mac_intro_repo" {
  title      = "Flux Key"
  repository = "mac-intro"
  key        = tls_private_key.mac_deploy_key.public_key_openssh
  read_only  = "false"
}

# creates flux namespace
resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux"
  }
  depends_on = [
    time_sleep.sleep_for_cluster_fix_helm_6361,

  ]
}

# resource "kubernetes_namespace" "cert_manager" {
#   metadata {
#     name = "cert-manager"
#   }
#   depends_on = [
#     time_sleep.sleep_for_cluster_fix_helm_6361,

#   ]
# }

# creates kubernetes secret for flux to pull changes from github and sync with gke
resource "kubernetes_secret" "flux_ssh" {
  metadata {
    name      = "flux-ssh"
    namespace = "flux"
  }
  data = {
    "identity" = "${tls_private_key.mac_deploy_key.private_key_pem}"
  }
  depends_on = [
    kubernetes_namespace.flux,
    tls_private_key.mac_deploy_key,
    time_sleep.sleep_for_cluster_fix_helm_6361
  ]
}

# creates flux values.yaml file
data "template_file" "flux_yaml" {
  template = file("${path.module}/templates/values-files/flux-values.yaml.tpl")

  vars = {
    EMAIL    = var.email_address
    USERNAME = var.username
    REPO     = var.repo
  }
}

# creates the flux values.yaml file from the redered data above
resource "local_file" "flux_yaml" {
  content    = data.template_file.flux_yaml.rendered
  filename   = "${path.module}/values-files/flux-values.yaml"
  depends_on = [kubernetes_namespace.flux, time_sleep.sleep_for_cluster_fix_helm_6361]
}

# creates flux helmrelease
resource "helm_release" "fluxcd" {
  name          = "flux"
  repository    = "https://charts.fluxcd.io"
  namespace     = "flux"
  chart         = "flux"
  version       = "1.6.0"
  recreate_pods = "true"
  wait          = "false"

  values = [data.template_file.flux_yaml.rendered]
  depends_on = [
    kubernetes_secret.flux_ssh,
    data.template_file.flux_yaml,
    kubernetes_namespace.flux,
    time_sleep.sleep_for_cluster_fix_helm_6361,
  ]
}

resource "helm_release" "ingress_nginx" {
  name         = "ingress-nginx"
  repository   = "https://kubernetes.github.io/ingress-nginx"
  namespace    = "nginx"
  chart        = "ingress-nginx"
  version      = "3.19.0"
  timeout      = "300"
  force_update = "true"

  values = [
    "${data.template_file.ingress_nginx.rendered}"
  ]
  depends_on = [
    time_sleep.nginx_helm,
    kubernetes_namespace.nginx,
    google_compute_address.nginx,
    data.template_file.ingress_nginx,
  ]
}

# creates monitoring namespace
resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}

# deploys prom_stack helmrelease
# resource "helm_release" "prom_stack" {
#   name         = "kube-prometheus-stack"
#   repository   = "https://prometheus-community.github.io/helm-charts"
#   namespace    = "monitoring"
#   chart        = "kube-prometheus-stack"
#   version      = "12.3.0"
#   timeout      = "300"
#   force_update = "true"

#   values = [
#     "${file("${path.module}/values-files/prom-stack-values.yaml")}"
#   ]
#   depends_on = [
#     time_sleep.nginx_helm,
#     kubernetes_namespace.monitoring,
#   ]
# }

