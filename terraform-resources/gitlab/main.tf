module "project" {
  source = "../"
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

locals {
  gitlab_db_name = var.gitlab_db_random_prefix ? "${var.gitlab_db_name}-${random_id.suffix[0].hex}" : var.gitlab_db_name
}

resource "random_id" "suffix" {
  count = var.gitlab_db_random_prefix ? 1 : 0

  byte_length = 4
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
    load_config_file       = false
    cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
    host                   = module.gke_auth.host
    token                  = module.gke_auth.token
  }
}

provider "kubernetes" {
  load_config_file = false

  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  host                   = module.gke_auth.host
  token                  = module.gke_auth.token
}

// Services
module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 9.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "redis.googleapis.com"
  ]
}

// GCS Service Account
resource "google_service_account" "gitlab_gcs" {
  project      = var.project_id
  account_id   = "gitlab-gcs"
  display_name = "GitLab Cloud Storage"
}

resource "google_service_account_key" "gitlab_gcs" {
  service_account_id = google_service_account.gitlab_gcs.name
}

resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gitlab_gcs.email}"
}

// Networking
resource "google_compute_network" "gitlab" {
  name                    = "gitlab"
  project                 = module.project_services.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "gitlab"
  ip_cidr_range = var.gitlab_nodes_subnet_cidr
  region        = var.region
  network       = google_compute_network.gitlab.self_link

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
  depends_on   = [module.project_services.project_id]
  count        = var.gitlab_address_name == "" ? 1 : 0
}

// Database
resource "google_compute_global_address" "gitlab_sql" {
  provider      = google-beta
  project       = var.project_id
  name          = "gitlab-sql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = google_compute_network.gitlab.self_link
  address       = "10.1.0.0"
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.gitlab.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gitlab_sql.name]
  depends_on              = [module.project_services.project_id]
}

resource "google_sql_database_instance" "gitlab_db" {
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  name             = local.gitlab_db_name
  region           = var.region
  database_version = "POSTGRES_11"

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
  depends_on = [google_sql_user.gitlab]
}

resource "random_string" "autogenerated_gitlab_db_password" {
  length  = 16
  special = false
}

resource "google_sql_user" "gitlab" {
  name     = "gitlab"
  instance = google_sql_database_instance.gitlab_db.name

  password = var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result
}

// Redis
resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = "STANDARD_HA"
  memory_size_gb     = 5
  region             = var.region
  authorized_network = google_compute_network.gitlab.self_link

  depends_on = [module.project_services.project_id]

  display_name = "GitLab Redis"
}

// Cloud Storage
resource "google_storage_bucket" "gitlab-backups" {
  name     = "${var.project_id}-gitlab-backups"
  location = var.region
}

resource "google_storage_bucket" "gitlab-uploads" {
  name     = "${var.project_id}-gitlab-uploads"
  location = var.region
}

resource "google_storage_bucket" "gitlab-artifacts" {
  name     = "${var.project_id}-gitlab-artifacts"
  location = var.region
}

resource "google_storage_bucket" "git-lfs" {
  name     = "${var.project_id}-git-lfs"
  location = var.region
}

resource "google_storage_bucket" "gitlab-packages" {
  name     = "${var.project_id}-gitlab-packages"
  location = var.region
}

resource "google_storage_bucket" "gitlab-registry" {
  name     = "${var.project_id}-registry"
  location = var.region
}

resource "google_storage_bucket" "gitlab-pseudo" {
  name     = "${var.project_id}-pseudo"
  location = var.region
}

resource "google_storage_bucket" "gitlab-runner-cache" {
  name     = "${var.project_id}-runner-cache"
  location = var.region
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
      name         = "gitlab"
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

data "template_file" "helm_values" {
  template = "${file("${path.module}/values.yaml.tpl")}"

  vars = {
    DOMAIN                = local.domain
    INGRESS_IP            = local.gitlab_address
    DB_PRIVATE_IP         = google_sql_database_instance.gitlab_db.private_ip_address
    REDIS_PRIVATE_IP      = google_redis_instance.gitlab.host
    PROJECT_ID            = var.project_id
    CERT_MANAGER_EMAIL    = var.certmanager_email
    GITLAB_RUNNER_INSTALL = var.gitlab_runner_install
  }
}

resource "time_sleep" "sleep_for_cluster_fix_helm_6361" {
  create_duration  = "180s"
  destroy_duration = "180s"
  depends_on       = [module.gke.endpoint, google_sql_database.gitlabhq_production]
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab"
  version    = var.helm_chart_version
  timeout    = 1200

  values = [data.template_file.helm_values.rendered]

  depends_on = [
    google_redis_instance.gitlab,
    google_sql_user.gitlab,
    kubernetes_storage_class.pd-ssd,
    time_sleep.sleep_for_cluster_fix_helm_6361,
  ]
}