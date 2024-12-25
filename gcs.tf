locals {
  storage_bucket_name = "${local.default_name}-storage"
}

resource "google_storage_hmac_key" "key" {
  project               = var.project_id
  service_account_email = google_service_account.gcs_service_account.email
  state                 = "ACTIVE"
}

module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "9.0.0"

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
  storage_class   = "STANDARD"
  prefix          = ""
  project_id      = var.project_id
  set_admin_roles = true
  versioning = {
    (local.storage_bucket_name) = false
  }

  depends_on = [google_storage_hmac_key.key]
}
