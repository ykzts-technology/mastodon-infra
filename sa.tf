module "service_accounts" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.5.3"

  generate_keys = true
  names         = ["terraform"]
  project_id    = var.project_id
  project_roles = [
    "${var.project_id}=>roles/cloudsql.admin",
    "${var.project_id}=>roles/compute.networkAdmin",
    "${var.project_id}=>roles/compute.securityAdmin",
    "${var.project_id}=>roles/compute.viewer",
    "${var.project_id}=>roles/container.clusterAdmin",
    "${var.project_id}=>roles/container.developer",
    "${var.project_id}=>roles/dns.admin",
    "${var.project_id}=>roles/iam.serviceAccountAdmin",
    "${var.project_id}=>roles/iam.serviceAccountKeyAdmin",
    "${var.project_id}=>roles/iam.serviceAccountUser",
    "${var.project_id}=>roles/redis.admin",
    "${var.project_id}=>roles/resourcemanager.projectIamAdmin",
    "${var.project_id}=>roles/storage.hmacKeyAdmin",
    "${var.project_id}=>roles/storage.admin",
  ]
}

resource "random_id" "gcs_service_account_suffix" {
  byte_length = 4
}

resource "google_service_account" "gcs_service_account" {
  account_id = "tf-gcs-${random_id.gcs_service_account_suffix.hex}"
  project    = var.project_id
}
