resource "google_artifact_registry_repository" "this" {
  for_each = toset(var.names)

  provider = google-beta

  format        = "DOCKER"
  location      = var.region
  project       = var.project
  repository_id = each.value
}
