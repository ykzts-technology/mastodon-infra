terraform {
  cloud {
    organization = "ykzts-technology"

    workspaces {
      name = "mastodon"
    }
  }
}

locals {
  cluster_type           = "mastodon"
  master_auth_subnetwork = "mastodon-master-subnet"
  network_name           = "mastodon-network"
  pods_range_name        = "ip-range-pods-mastodon"
  subnet_name            = "mastodon-subnet"
  subnet_names           = [for subnet_self_link in module.vpc.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
  svc_range_name         = "ip-range-svc-mastodon"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "5.0.0"

  network_name = local.network_name
  project_id   = var.project_id
  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = local.svc_range_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
  subnets = [
    {
      subnet_name   = local.subnet_name
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
    {
      subnet_name   = local.master_auth_subnetwork
      subnet_ip     = "10.60.0.0/17"
      subnet_region = var.region
    },
  ]
}

module "sql-db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "10.0.1"

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
  database_version    = "POSTGRES_9_6"
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
  name                            = var.db_instance_name
  project_id                      = var.project_id
  region                          = var.region
  tier                            = "db-g1-small"
  update_timeout                  = "30m"
  user_name                       = "postgres"
  zone                            = "${var.region}-c"
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
