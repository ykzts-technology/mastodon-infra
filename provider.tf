provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
}
