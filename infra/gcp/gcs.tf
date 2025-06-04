resource "google_storage_bucket" "project_gcs_bucket" {
  name     = "ns-gcs-sigma-outcome"
  location = var.gcp_region

  versioning {
    enabled = true
  }

  labels = {
    managed_by = "terraform"
    purpose    = "terraform_state_and_functions"
  }
}
