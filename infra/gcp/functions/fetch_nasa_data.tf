resource "google_cloudfunctions2_function" "fetch_nasa_data" {
  name     = "ns-func-fetch-nasa-data"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket.project_bucket.name
        object = "sources/functions/fetch_nasa_data.zip"
      }
    }
  }

  service_config {
    service_account_email = var.deployer_sa_email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.daily_fetch_topic.id
  }
}
