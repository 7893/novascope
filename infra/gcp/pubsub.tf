resource "google_pubsub_topic" "daily_fetch_topic" {
  name = "ns-ps-daily-nasa-fetch"
  labels = {
    managed_by = "terraform"
    purpose    = "nasa_daily_job"
  }
}
