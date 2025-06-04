resource "google_cloudfunctions2_function" "api_nasa_data" {
  name     = "ns-api-nasa-data"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket.project_bucket.name
        object = "sources/functions/api_nasa_data.zip"
      }
    }
  }

  service_config {
    service_account_email = google_service_account.functions.email
    ingress_settings      = "ALLOW_ALL"
  }

  labels = {
    type = "http"
  }
}
