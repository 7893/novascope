resource "google_storage_bucket" "project_bucket" {
  name                        = "ns-gcs-sigma-outcome"
  location                    = var.region
  uniform_bucket_level_access = true
}
