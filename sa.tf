resource "random_id" "gcs_service_account_suffix" {
  byte_length = 4
}

resource "google_service_account" "gcs_service_account" {
  account_id = "tf-gcs-${random_id.gcs_service_account_suffix.hex}"
  project    = var.project_id
}
