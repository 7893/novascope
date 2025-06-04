resource "google_monitoring_alert_policy" "function_failure" {
  display_name = "Function Failure"
  combiner     = "OR"

  conditions {
    display_name = "Error count"
    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.label.status=\"failure\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      trigger { count = 1 }
    }
  }
}

resource "google_monitoring_alert_policy" "scheduler_failure" {
  display_name = "Scheduler Failure"
  combiner     = "OR"

  conditions {
    display_name = "Job failed"
    condition_threshold {
      filter          = "metric.type=\"cloudscheduler.googleapis.com/job/attempt_count\" AND metric.label.result=\"failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      trigger { count = 1 }
    }
  }
}
