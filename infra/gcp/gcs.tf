resource "google_storage_bucket" "project_gcs_bucket" {
  name          = "ns-gcs-sigma-outcome"
  location      = var.gcp_region 
  storage_class = "STANDARD"
  force_destroy = false

  versioning {
    enabled = true
  }

  labels = {
    managed_by = "terraform"
    purpose    = "terraform_state_and_functions"
  }

  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}