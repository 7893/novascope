resource "google_cloud_scheduler_job" "daily_fetch_job" {
  name        = "ns-sched-daily-fetch"
  description = "Daily job to trigger NASA data fetch"
  schedule    = "0 2 * * *" # 每天北京时间10点，可根据需求调整
  time_zone   = "Asia/Shanghai"

  pubsub_target {
    topic_name = google_pubsub_topic.daily_fetch_topic.id
    data       = base64encode("{}")
  }
}
