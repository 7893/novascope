resource "google_cloudfunctions2_function" "api_nasa_data" {
  name     = "ns-api-nasa-data"
  location = var.gcp_region # 修正: 使用 var.gcp_region

  build_config {
    runtime     = "python311" # 确保这是您项目支持的最新LTS Python版本之一
    entry_point = "main" # 假设您的Python函数入口点是main
    source {
      storage_source {
        bucket = google_storage_bucket.project_gcs_bucket.name # 修正: 使用 project_gcs_bucket
        object = "sources/functions/api_nasa_data.zip" # 确保这个zip包路径正确
      }
    }
  }

  service_config {
    service_account_email = var.deployer_sa_email
    ingress_settings      = "ALLOW_ALL" # 对于公开API是必须的
    # available_memory = "256MiB" # 根据需要调整
    # timeout_seconds = 60 # 根据需要调整
  }

  labels = {
    type = "http"
  }
}