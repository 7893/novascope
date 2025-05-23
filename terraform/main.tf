# novascope/terraform/main.tf

# 1. GCS Bucket for Cloud Functions Source Code
resource "google_storage_bucket" "ns_functions_source_bucket" {
  name                        = var.gcs_bucket_for_functions_source_name
  project                     = var.gcp_project_id
  location                    = var.gcp_region
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"

  versioning {
    enabled = true
  }

  labels = {
    "project"     = "novascope"
    "environment" = "common"
    "purpose"     = "cloud-functions-source"
  }
}

# 2. Cloudflare R2 Bucket for APOD Images
resource "cloudflare_r2_bucket" "ns_apod_images_bucket" {
  account_id = var.cloudflare_account_id # 从 variables.tf (通过 terraform.tfvars 赋值) 获取账户 ID
  name       = "${var.resource_prefix}-r2-${var.r2_bucket_name_suffix}" # 构建名称: ns-r2-apod-images
  location   = "APAC"
}

# 3. GCP Secret Manager Secret Containers
resource "google_secret_manager_secret" "ns_nasa_api_key_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-nasa-api-key"

  replication {
    auto {}
  }

  labels = {
    "project" = "novascope"
    "purpose" = "nasa-api-key"
  }
}

resource "google_secret_manager_secret" "ns_r2_access_key_id_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-r2-access-key-id"

  replication {
    auto {}
  }

  labels = {
    "project" = "novascope"
    "purpose" = "cloudflare-r2-credentials"
  }
}

resource "google_secret_manager_secret" "ns_r2_secret_access_key_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-r2-secret-access-key"

  replication {
    auto {}
  }

  labels = {
    "project" = "novascope"
    "purpose" = "cloudflare-r2-credentials"
  }
}

resource "google_secret_manager_secret" "ns_cf_worker_shared_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-cf-worker-shared-secret"

  replication {
    auto {}
  }

  labels = {
    "project" = "novascope"
    "purpose" = "worker-to-gcp-function-auth"
  }
}

# novascope/terraform/main.tf (在文件末尾添加以下内容)

# 4. Pub/Sub Topic for triggering the fetch function
resource "google_pubsub_topic" "ns_apod_fetch_trigger_topic" {
  project = var.gcp_project_id
  name    = "${var.resource_prefix}-ps-daily-apod-trigger" # 例如: ns-ps-daily-apod-trigger
  labels = {
    "project" = "novascope"
    "purpose" = "apod-fetch-trigger"
  }
}

# 5. Archive the Go function source code
data "archive_file" "ns_fetch_apod_function_source" {
  type        = "zip"
  source_dir  = "../gcp_functions_go/ns-func-fetch-apod/" # 指向您的Go函数代码目录
  output_path = "/tmp/${var.resource_prefix}-func-fetch-apod.zip"

  # 确保在重新打包时，文件的修改时间戳不会导致不必要的 Terraform diff
  # 这通常不是必需的，除非您遇到因为时间戳导致的不必要更新
  # output_file_mode = "0644" # 设置文件权限
}

# 6. Upload the archived function source to GCS
resource "google_storage_bucket_object" "ns_fetch_apod_function_archive" {
  name   = "${var.resource_prefix}-func-fetch-apod-source-v${data.archive_file.ns_fetch_apod_function_source.output_md5}.zip" # 基于 MD5 的版本化文件名
  bucket = google_storage_bucket.ns_functions_source_bucket.name // 引用我们之前创建的源码桶
  source = data.archive_file.ns_fetch_apod_function_source.output_path # Path to the zipped archive
}

# 7. Define the ns-func-fetch-apod Cloud Function (2nd Gen)
resource "google_cloudfunctions2_function" "ns_fetch_apod_function" {
  project  = var.gcp_project_id
  name     = "${var.resource_prefix}-func-fetch-apod" # 例如: ns-func-fetch-apod
  location = var.gcp_region

  description = "Daily function to fetch APOD data, store image to R2, and metadata to Firestore."

  build_config {
    runtime     = "go122" # 对应您的 Go 1.22.x 版本
    entry_point = "FetchAndStoreAPOD" // Go 代码中的函数名
    environment_variables = {
      "GCP_PROJECT_ID"                 = var.gcp_project_id
      "NASA_API_KEY_SECRET_ID"         = google_secret_manager_secret.ns_nasa_api_key_secret_container.secret_id
      "R2_ACCESS_KEY_ID_SECRET_ID"     = google_secret_manager_secret.ns_r2_access_key_id_secret_container.secret_id
      "R2_SECRET_KEY_SECRET_ID"        = google_secret_manager_secret.ns_r2_secret_access_key_secret_container.secret_id
      "R2_BUCKET_NAME"                 = cloudflare_r2_bucket.ns_apod_images_bucket.name
      "CLOUDFLARE_ACCOUNT_ID"          = var.cloudflare_account_id // 从 variables.tf 获取
      "FIRESTORE_COLLECTION_ID"        = "ns-fs-apod-metadata"     // 我们规划的 Firestore 集合名
      // R2_ENDPOINT 会在 Go 代码的 init() 函数中根据 CLOUDFLARE_ACCOUNT_ID 构造
    }
    source {
      storage_source {
        bucket = google_storage_bucket_object.ns_fetch_apod_function_archive.bucket
        object = google_storage_bucket_object.ns_fetch_apod_function_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 3
    available_memory   = "256Mi" # 根据需要调整
    timeout_seconds    = 500      # APOD 获取和图片处理可能需要较长时间，最大可设为540 (9分钟)
    
    # 使用我们之前同意的 Compute Engine 默认服务账号
    # 如果您创建了专用的 sa-ns-functions，请替换成它的邮箱
    service_account_email = "817261716888-compute@developer.gserviceaccount.com" 

    # 对于 Pub/Sub 触发的函数，ingress 通常是内部的或由 Eventarc 控制
    ingress_settings               = "ALLOW_INTERNAL_ONLY" 
    all_traffic_on_latest_revision = true
  }

  event_trigger {
    trigger_region = var.gcp_region // 通常与函数在同一区域
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.ns_apod_fetch_trigger_topic.id // 引用上面创建的 Pub/Sub 主题
    retry_policy   = "RETRY_POLICY_RETRY" // 如果失败则重试
  }

  labels = {
    "project"     = "novascope"
    "environment" = "common"
    "purpose"     = "daily-apod-fetcher"
  }

  depends_on = [
    google_project_service.firestore_api, // 确保 Firestore API 已启用
    google_project_service.cloudfunctions_api, // 确保 Cloud Functions API 已启用
    google_project_service.cloudbuild_api, // Cloud Build 用于构建函数
    google_project_service.secretmanager_api, // 函数需要访问 Secret Manager
    // Pub/Sub API (google.pubsub.googleapis.com) 通常也需要，如果没启用可以加上
    // google_project_service.pubsub_api
    google_project_service.eventarc_api 
  ]
}

# (可选，但推荐) 确保 Cloud Build 服务账号有权从 GCS 源码桶读取源码
# Cloud Build 服务账号格式: service-[PROJECT_NUMBER]@gcp-sa-cloudbuild.iam.gserviceaccount.com
# PROJECT_NUMBER 是您的数字项目编号，可以通过 `gcloud projects describe YOUR_PROJECT_ID --format="value(projectNumber)"` 获取
# data "google_project" "project" {
#   project_id = var.gcp_project_id
# }
# resource "google_storage_bucket_iam_member" "ns_cloud_build_source_bucket_reader" {
#   bucket = google_storage_bucket.ns_functions_source_bucket.name
#   role   = "roles/storage.objectViewer"
#   member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
# }

# 8. Define the Cloud Scheduler job
resource "google_cloud_scheduler_job" "ns_daily_apod_fetch_scheduler" {
  project   = var.gcp_project_id
  region    = var.gcp_region
  name      = "${var.resource_prefix}-sched-daily-apod-fetch" # 例如: ns-sched-daily-apod-fetch
  schedule  = "0 5 * * *" # 每天 UTC 时间早上 5 点运行 (北京/东京时间下午1-2点左右)
  time_zone = "Etc/UTC"   # 使用 UTC 时间以避免夏令时问题

  description = "Daily job to trigger the APOD fetch Cloud Function."

  pubsub_target {
    topic_name = google_pubsub_topic.ns_apod_fetch_trigger_topic.id // 目标是我们创建的 Pub/Sub 主题
    data       = base64encode("{\"source\":\"cloud-scheduler\"}")  // 发送给 Pub/Sub 的可选消息体，需要 base64 编码
  }

  attempt_deadline = "320s" # 作业尝试的截止时间，应小于或等于函数的超时时间

  depends_on = [
    google_cloudfunctions2_function.ns_fetch_apod_function,
    google_project_service.cloudscheduler_api // 确保 Scheduler API 已启用
  ]
}

# (可选，但推荐) 为 Scheduler 作业的服务账号授予向 Pub/Sub 主题发布的权限
# Scheduler 作业通常使用一个 GCP 管理的服务账号来执行操作。
# 这个服务账号格式: service-[PROJECT_NUMBER]@gcp-sa-cloudscheduler.iam.gserviceaccount.com
# 它需要 roles/pubsub.publisher 权限才能向 Pub/Sub 主题发布消息。
# data "google_project" "project" {} # 如果上面没有取消注释，这里也需要
# resource "google_pubsub_topic_iam_member" "ns_scheduler_pubsub_publisher" {
#   project = var.gcp_project_id
#   topic   = google_pubsub_topic.ns_apod_fetch_trigger_topic.name
#   role    = "roles/pubsub.publisher"
#   member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
# }


# 为了让 depends_on 更清晰，我们明确声明依赖的 API 服务启用
resource "google_project_service" "cloudfunctions_api" {
  project                    = var.gcp_project_id
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = false # 通常我们希望启用相关依赖
  disable_on_destroy         = false # 在销毁时不禁用 API (可选)
}

resource "google_project_service" "cloudbuild_api" {
  project = var.gcp_project_id
  service = "cloudbuild.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_api" {
  project = var.gcp_project_id
  service = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

// Firestore API 和 Scheduler API 在 Phase 2 中应该已经通过 gcloud enable 启用了
// 如果没有，也可以在这里用 google_project_service 定义，例如：
resource "google_project_service" "firestore_api" {
  project = var.gcp_project_id
  service = "firestore.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "cloudscheduler_api" {
  project = var.gcp_project_id
  service = "cloudscheduler.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "pubsub_api" { // Pub/Sub API
  project = var.gcp_project_id
  service = "pubsub.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

# novascope/terraform/main.tf (在文件末尾或其他 google_project_service 资源附近添加)

resource "google_project_service" "eventarc_api" {
  project                    = var.gcp_project_id
  service                    = "eventarc.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}