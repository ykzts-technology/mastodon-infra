terraform {
  cloud {
    organization = "ykzts-technology"

    workspaces {
      name = "mastodon"
    }
  }
}

locals {
  default_name           = var.project_id
  cluster_type           = "mastodon"
  master_auth_subnetwork = "mastodon-master-subnet"
  network_name           = "mastodon-network"
  pods_range_name        = "ip-range-pods-mastodon"
  subnet_name            = "mastodon-subnet"
  subnet_names           = [for subnet_self_link in module.vpc.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
  svc_range_name         = "ip-range-svc-mastodon"
}

resource "google_compute_ssl_policy" "default" {
  name            = "default-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

module "datasource-syncer-workload-identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "32.0.4"

  name       = "datasource-syncer"
  namespace  = "default"
  project_id = var.project_id
  roles      = ["roles/monitoring.viewer", "roles/iam.serviceAccountTokenCreator"]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-public-cluster"
  version = "32.0.4"

  create_service_account          = false
  enable_vertical_pod_autoscaling = true
  gateway_api_channel             = "CHANNEL_STANDARD"
  ip_range_pods                   = local.pods_range_name
  ip_range_services               = local.svc_range_name
  name                            = "${local.cluster_type}-cluster"
  network                         = module.vpc.network_name
  project_id                      = var.project_id
  region                          = var.region
  release_channel                 = "REGULAR"
  subnetwork                      = local.subnet_names[index(module.vpc.subnets_names, local.subnet_name)]
}

module "mastodon-secrets" {
  source = "./modules/mastodon-secrets"

  active_record_encryption_key_derivation_salt = var.active_record_encryption_key_derivation_salt
  active_record_encryption_deterministic_key   = var.active_record_encryption_deterministic_key
  active_record_encryption_primary_key         = var.active_record_encryption_primary_key
  deepl_api_key                                = var.deepl_api_key
  db_hostname                                  = module.sql-db.private_ip_address
  db_password                                  = module.sql-db.additional_users[0].password
  db_username                                  = module.sql-db.additional_users[0].name
  es_hostname                                  = var.es_hostname
  es_password                                  = var.es_password
  es_port                                      = var.es_port
  es_username                                  = var.es_username
  redis_hostname                               = module.memorystore.host
  redis_password                               = module.memorystore.auth_string
  redis_port                                   = module.memorystore.port
  smtp_password                                = var.smtp_password
  storage_access_key                           = google_storage_hmac_key.key.access_id
  storage_bucket                               = "ykzts-technology-storage"
  storage_endpoint                             = "https://storage.googleapis.com"
  storage_hostname                             = "storage.googleapis.com"
  storage_region                               = "ap-northeast-1"
  storage_secret_key                           = google_storage_hmac_key.key.secret
  vapid_private_key                            = var.vapid_private_key
  vapid_public_key                             = var.vapid_public_key
}

resource "kubernetes_secret" "grafana" {
  data = {
    api-token       = var.grafana_api_token
    datasource-uids = var.grafana_datasource_uids
  }

  metadata {
    name = "grafana-credentials"
  }
}
