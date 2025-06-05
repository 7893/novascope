/*
resource "google_monitoring_alert_policy" "function_failure" {
  display_name = "Function Failure"
  combiner     = "OR"

  conditions {
    display_name = "Error count"
    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.label.status=\"failure\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"  # 持续0秒立即触发
      trigger { count = 1 }   # 发生1次就触发

      # 修正点1: 添加 aggregations 块
      aggregations {
        alignment_period   = "300s"  # 聚合周期，例如5分钟
        per_series_aligner = "ALIGN_COUNT" # 对齐方式，计算周期内的次数
      }
    }
  }
}

resource "google_monitoring_alert_policy" "scheduler_failure" {
  display_name = "Scheduler Failure"
  combiner     = "OR"

  conditions {
    display_name = "Job failed"
    condition_threshold {
      # 修正点2: 修改 filter 中的 resource.type
      filter          = "resource.type=\"cloud_scheduler_job\" AND metric.type=\"cloudscheduler.googleapis.com/job/attempt_count\" AND metric.label.result=\"failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"  # 持续0秒立即触发
      trigger { count = 1 }   # 发生1次就触发
      
      # 确保这里也是 aggregations (复数)
      aggregations {
        alignment_period   = "3600s" # 聚合周期，例如1小时
        per_series_aligner = "ALIGN_COUNT" # 对齐方式，计算周期内的次数
      }
    }
  }
}
*/