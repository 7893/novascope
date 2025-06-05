resource "google_cloudfunctions2_function" "fetch_nasa_data" {
  name     = "ns-func-fetch-nasa-data"
  location = var.gcp_region # 修正: 使用 var.gcp_region

  build_config {
    runtime     = "python311" # 确保这是您项目支持的最新LTS Python版本之一
    entry_point = "main" # 假设您的Python函数入口点是main
    source {
      storage_source {
        bucket = google_storage_bucket.project_gcs_bucket.name # 修正: 使用 project_gcs_bucket
        object = "sources/functions/fetch_nasa_data.zip" # 确保这个zip包路径正确
      }
    }
  }

  service_config {
    service_account_email = var.deployer_sa_email
    # available_memory = "512MiB" # 根据数据处理量调整
    # timeout_seconds = 300 # 对于可能耗时较长的数据抓取，建议增加超时
  }

  event_trigger {
    trigger_region = var.gcp_region # 通常与函数location一致
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.daily_fetch_topic.id
    # retry_policy = "RETRY_POLICY_RETRY" # 考虑添加重试策略
  }
}