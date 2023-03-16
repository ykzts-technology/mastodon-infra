module "sql-db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "14.0.1"

  additional_users = [
    {
      name            = "mastodon"
      password        = null
      random_password = true
    },
  ]
  availability_type = "ZONAL"
  backup_configuration = {
    enabled                        = true
    location                       = "asia"
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
  name                            = local.default_name
  project_id                      = var.project_id
  region                          = var.region
  tier                            = "db-custom-1-3840"
  update_timeout                  = "30m"
  user_name                       = "postgres"
  zone                            = "${var.region}-c"
}

module "memorystore" {
  source  = "terraform-google-modules/memorystore/google"
  version = "7.1.0"

  auth_enabled            = true
  authorized_network      = module.vpc.network_id
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  memory_size_gb          = 1
  name                    = local.default_name
  project                 = var.project_id
  redis_version           = "REDIS_6_X"
  region                  = var.region
  tier                    = "BASIC"
  transit_encryption_mode = "DISABLED"
}
