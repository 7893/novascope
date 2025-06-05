resource "google_cloudfunctions2_function" "fetch_nasa_data" {
  name     = "ns-func-fetch-nasa-data"
  location = var.gcp_region

  build_config {
    runtime     = "python311"
    entry_point = "main"      // 请确认您的 apps/gcp-py-fetch-nasa-data/main.py 中入口函数名为 main
    source {
      storage_source {
        bucket = google_storage_bucket.project_gcs_bucket.name
        object = "sources/functions/fetch_nasa_data.zip"         // 请确认此 .zip 包已按此名称和路径上传到 GCS
      }
    }
  }

  service_config {
    service_account_email = var.deployer_sa_email
    available_memory      = "512Mi"  // 建议根据实际需要调整
    timeout_seconds       = 300       // 建议设置为几分钟，例如300秒 (5分钟) 或 540秒 (9分钟)
  }

  event_trigger {
    trigger_region = var.gcp_region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.daily_fetch_topic.id
    retry_policy   = "RETRY_POLICY_RETRY" // 建议启用重试
  }
}