terraform {
  cloud {
    organization = "ykzts-technology"

    workspaces {
      name = "mastodon"
    }
  }
}

locals {
  storage_bucket_name    = "${var.name}-storage"
  cluster_type           = "mastodon"
  master_auth_subnetwork = "mastodon-master-subnet"
  network_name           = "mastodon-network"
  pods_range_name        = "ip-range-pods-mastodon"
  subnet_name            = "mastodon-subnet"
  subnet_names           = [for subnet_self_link in module.vpc.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
  svc_range_name         = "ip-range-svc-mastodon"
}

data "google_client_config" "default" {}

module "address-fe" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.1"

  address_type = "EXTERNAL"
  global       = true
  ip_version   = "IPV4"
  names        = ["${var.name}-ip"]
  project_id   = var.project_id
  region       = var.region
}

module "dns-public-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "4.1.0"

  dnssec_config = {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
  }
  domain     = "${var.domain}."
  name       = var.name
  project_id = var.project_id
  recordsets = [
    {
      name    = ""
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = "www"
      records = ["ghs.googlehosted.com."]
      ttl     = 7200
      type    = "CNAME"
    },
    {
      name    = "files"
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = "_github-challenge-ykzts-technology-organization"
      records = ["a0fb7df9f0"]
      ttl     = 3600
      type    = "TXT"
    }
  ]
  type = "public"
}

module "sql-db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "10.0.1"

  additional_users = [
    {
      name     = "mastodon"
      password = null
    },
  ]
  availability_type = "ZONAL"
  backup_configuration = {
    enabled                        = true
    location                       = null
    point_in_time_recovery_enabled = false
    retained_backups               = 7
    retention_unit                 = "COUNT"
    start_time                     = "18:00"
    transaction_log_retention_days = 7
  }
  create_timeout = "30m"
  database_flags = [
    {
      name  = "autovacuum"
      value = "on"
    },
    {
      name  = "checkpoint_completion_target"
      value = "0.7"
    },
    {
      name  = "default_statistics_target"
      value = "100"
    },
    {
      name  = "maintenance_work_mem"
      value = "108800"
    },
    {
      name  = "max_connections"
      value = "128"
    },
    {
      name  = "max_wal_size"
      value = "128"
    },
    {
      name  = "random_page_cost"
      value = "1.1"
    },
    {
      name  = "work_mem"
      value = "6800"
    },
  ]
  database_version    = "POSTGRES_14"
  db_charset          = "UTF8"
  db_collation        = "en_US.UTF8"
  db_name             = "postgres"
  delete_timeout      = "30m"
  deletion_protection = true
  disk_autoresize     = true
  disk_size           = 37
  disk_type           = "PD_SSD"
  enable_default_db   = true
  enable_default_user = true
  insights_config = {
    query_string_length     = 1024
    record_application_tags = false
    record_client_address   = false
  }
  ip_configuration = {
    allocated_ip_range  = null
    authorized_networks = []
    ipv4_enabled        = false
    private_network     = module.vpc.network_id
    require_ssl         = false
  }
  maintenance_window_day          = 1
  maintenance_window_hour         = 19
  maintenance_window_update_track = "stable"
  name                            = var.name
  project_id                      = var.project_id
  region                          = var.region
  tier                            = "db-g1-small"
  update_timeout                  = "30m"
  user_name                       = "postgres"
  zone                            = "${var.region}-c"
}

module "memorystore" {
  source  = "terraform-google-modules/memorystore/google"
  version = "4.3.0"

  auth_enabled            = true
  authorized_network      = module.vpc.network_id
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  memory_size_gb          = 1
  name                    = var.name
  project                 = var.project_id
  redis_version           = "REDIS_6_X"
  region                  = var.region
  tier                    = "BASIC"
  transit_encryption_mode = "DISABLED"
}

resource "google_storage_hmac_key" "key" {
  project               = var.project_id
  service_account_email = google_service_account.gcs_service_account.email
  state                 = "ACTIVE"
}

module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "3.2.0"

  bucket_admins = {
    (local.storage_bucket_name) = "serviceAccount:${google_service_account.gcs_service_account.email}",
  }
  bucket_policy_only = {
    (local.storage_bucket_name) = false
  }
  cors = [
    {
      max_age_seconds = 3600
      method          = ["GET", "HEAD"]
      response_header = ["Content-Length"]
      origin          = ["https://${var.domain}"]
    },
  ]
  location        = "ASIA"
  names           = [local.storage_bucket_name]
  storage_class   = "MULTI_REGIONAL"
  prefix          = ""
  project_id      = var.project_id
  set_admin_roles = true
  versioning = {
    (local.storage_bucket_name) = false
  }

  depends_on = [google_storage_hmac_key.key]
}

resource "google_compute_ssl_policy" "default" {
  name            = "default-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-public-cluster"
  version = "20.0.0"

  enable_vertical_pod_autoscaling = true
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

  db_hostname        = module.sql-db.private_ip_address
  db_password        = module.sql-db.additional_users[0].password
  db_username        = module.sql-db.additional_users[0].name
  redis_hostname     = var.redis_hostname
  redis_password     = var.redis_password
  redis_port         = var.redis_port
  smtp_password      = var.smtp_password
  storage_access_key = google_storage_hmac_key.key.access_id
  storage_secret_key = google_storage_hmac_key.key.secret
  vapid_private_key  = var.vapid_private_key
  vapid_public_key   = var.vapid_public_key
}
