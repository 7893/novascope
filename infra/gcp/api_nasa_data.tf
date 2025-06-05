resource "google_cloudfunctions2_function" "api_nasa_data" {
  name     = "ns-api-nasa-data"
  location = var.gcp_region

  build_config {
    runtime     = "python311" 
    entry_point = "main"      // 请确认您的 apps/gcp-py-api-nasa-data/main.py (或主文件) 中入口函数名为 main
    source {
      storage_source {
        bucket = google_storage_bucket.project_gcs_bucket.name
        object = "sources/functions/api_nasa_data.zip"         // 请确认此 .zip 包已按此名称和路径上传到 GCS
      }
    }
  }

  service_config {
    service_account_email = var.deployer_sa_email
    ingress_settings      = "ALLOW_ALL"
    // available_memory = "256MiB" 
    // timeout_seconds = 60       
  }

  labels = {
    type = "http"
  }
}