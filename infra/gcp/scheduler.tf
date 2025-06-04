resource "google_cloud_scheduler_job" "daily_fetch_job" {
  name      = "ns-sched-daily-fetch"
  schedule  = "0 5 * * *"
  time_zone = "Asia/Hong_Kong"

  pubsub_target {
    topic_name = google_pubsub_topic.daily_fetch_topic.id
    data       = base64encode("{}")
  }
}
