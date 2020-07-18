resource "google_container_registry" "eu_registry" {
  project  = var.project_id
  location = "EU"
}