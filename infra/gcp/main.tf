provider "google" {
  project = var.gcp_project_id   # 或直接填 "sigma-outcome"
  region  = var.gcp_region       # 或直接填 "us-central1"
}
