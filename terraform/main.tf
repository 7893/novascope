# novascope/terraform/main.tf

# --- 定义统一的 GCS Bucket (将用于TF状态和函数源码) ---
resource "google_storage_bucket" "ns_unified_gcs_bucket" {
  name                        = var.gcs_unified_bucket_name
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
    "purpose"     = "unified-storage-tfstate-and-sources"
  }
}

# --- API Service Enablement ---
resource "google_project_service" "cloudfunctions_api" {
  project                    = var.gcp_project_id
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "cloudbuild_api" {
  project                    = var.gcp_project_id
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "secretmanager_api" {
  project                    = var.gcp_project_id
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "firestore_api" {
  project                    = var.gcp_project_id
  service                    = "firestore.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "cloudscheduler_api" {
  project                    = var.gcp_project_id
  service                    = "cloudscheduler.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "pubsub_api" {
  project                    = var.gcp_project_id
  service                    = "pubsub.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "eventarc_api" {
  project                    = var.gcp_project_id
  service                    = "eventarc.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

# --- Cloudflare R2 Bucket ---
resource "cloudflare_r2_bucket" "ns_apod_images_bucket" {
  account_id = var.cloudflare_account_id
  name       = "${var.resource_prefix}-r2-${var.r2_bucket_name_suffix}" # 构建名称: ns-r2-nasa-media
  location   = "APAC"
}

# --- GCP Secret Manager Secret Containers ---
resource "google_secret_manager_secret" "ns_nasa_api_key_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-nasa-api-key"

  replication {
    auto {}
  }

  labels = {
    project = "novascope"
    purpose = "nasa-api-key"
  }
}

resource "google_secret_manager_secret" "ns_r2_access_key_id_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-r2-access-key-id"

  replication {
    auto {}
  }

  labels = {
    project = "novascope"
    purpose = "cloudflare-r2-credentials"
  }
}

resource "google_secret_manager_secret" "ns_r2_secret_access_key_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-r2-secret-access-key"

  replication {
    auto {}
  }

  labels = {
    project = "novascope"
    purpose = "cloudflare-r2-credentials"
  }
}

resource "google_secret_manager_secret" "ns_cf_worker_shared_secret_container" {
  project   = var.gcp_project_id
  secret_id = "ns-sm-cf-worker-shared-secret"

  replication {
    auto {}
  }

  labels = {
    project = "novascope"
    purpose = "worker-to-gcp-function-auth"
  }
}

# --- GCP Pub/Sub Topic ---
resource "google_pubsub_topic" "ns_apod_fetch_trigger_topic" {
  project = var.gcp_project_id
  name    = "${var.resource_prefix}-ps-daily-apod-trigger"
  labels  = {
    project = "novascope"
    purpose = "apod-fetch-trigger"
  }
}

# --- GCP Function Source Archive and Upload ---
data "archive_file" "ns_fetch_apod_function_source" {
  type        = "zip"
  source_dir  = "../gcp_functions_go/ns-func-fetch-apod/" # 确保路径相对于 terraform/ 目录是正确的
  output_path = "/tmp/${var.resource_prefix}-func-fetch-apod.zip"
}

resource "google_storage_bucket_object" "ns_fetch_apod_function_archive" {
  name   = "${var.function_source_gcs_prefix}${var.resource_prefix}-func-fetch-apod-v${data.archive_file.ns_fetch_apod_function_source.output_md5}.zip"
  bucket = google_storage_bucket.ns_unified_gcs_bucket.name # 指向新定义的统一 GCS 桶
  source = data.archive_file.ns_fetch_apod_function_source.output_path # Path to the zipped archive
}

# --- GCP Cloud Function: ns-func-fetch-apod ---
resource "google_cloudfunctions2_function" "ns_fetch_apod_function" {
  project     = var.gcp_project_id
  name        = "${var.resource_prefix}-func-fetch-apod"
  location    = var.gcp_region
  description = "Daily function to fetch APOD data, store image to R2, and metadata to Firestore."

  labels = {
    project     = "novascope"
    environment = "common"
    purpose     = "daily-apod-fetcher"
  }

  build_config {
    runtime     = "go122"
    entry_point = "FetchAndStoreAPOD"
    environment_variables = {
      "GCP_PROJECT_ID"                 = var.gcp_project_id
      "NASA_API_KEY_SECRET_ID"         = google_secret_manager_secret.ns_nasa_api_key_secret_container.secret_id
      "R2_ACCESS_KEY_ID_SECRET_ID"     = google_secret_manager_secret.ns_r2_access_key_id_secret_container.secret_id
      "R2_SECRET_KEY_SECRET_ID"        = google_secret_manager_secret.ns_r2_secret_access_key_secret_container.secret_id
      "R2_BUCKET_NAME"                 = cloudflare_r2_bucket.ns_apod_images_bucket.name
      "CLOUDFLARE_ACCOUNT_ID"          = var.cloudflare_account_id
      "FIRESTORE_COLLECTION_ID"        = "ns-fs-apod-metadata"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.ns_unified_gcs_bucket.name # 指向新定义的统一 GCS 桶
        object = google_storage_bucket_object.ns_fetch_apod_function_archive.name
      }
    }
  }

  service_config {
    max_instance_count             = 3
    available_memory               = "256Mi"
    timeout_seconds                = 500
    service_account_email          = "817261716888-compute@developer.gserviceaccount.com" // 您选择的 SA
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
  }

  event_trigger {
    trigger_region = var.gcp_region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.ns_apod_fetch_trigger_topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  depends_on = [
    google_project_service.eventarc_api,
    google_project_service.cloudfunctions_api,
    google_project_service.cloudbuild_api,
    google_project_service.secretmanager_api,
    google_project_service.firestore_api,
    google_project_service.pubsub_api,
    google_storage_bucket.ns_unified_gcs_bucket // 函数依赖于统一桶的创建
  ]
}

# --- GCP Cloud Scheduler Job ---
resource "google_cloud_scheduler_job" "ns_daily_apod_fetch_scheduler" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  name        = "${var.resource_prefix}-sched-daily-apod-fetch"
  schedule    = "0 5 * * *" 
  time_zone   = "Etc/UTC"
  description = "Daily job to trigger the APOD fetch Cloud Function."

  pubsub_target {
    topic_name = google_pubsub_topic.ns_apod_fetch_trigger_topic.id
    data       = base64encode("{\"source\":\"cloud-scheduler\"}")
  }
  attempt_deadline = "320s"

  depends_on = [
    google_cloudfunctions2_function.ns_fetch_apod_function,
    google_project_service.cloudscheduler_api
  ]
}

# --- Cloudflare Worker Script (ns) - Placeholder for now ---
# resource "cloudflare_worker_script" "ns_frontend_worker" {
#   account_id = var.cloudflare_account_id
#   name       = var.worker_script_name // "ns"
#   content    = file("../cf_worker_ts/dist/placeholder.js") // 需要一个占位脚本
#
#   plain_text_bindings {
#     name = "GCP_API_URL" 
#     text = "placeholder_url_for_ns_func_get_metadata" 
#   }
#   secret_text_bindings {
#     name = "GCP_SHARED_SECRET"
#     text = "placeholder_for_actual_shared_secret_value_from_SM" 
#   }
#   r2_bucket_binding {
#     name        = "MEDIA_BUCKET"
#     bucket_name = cloudflare_r2_bucket.ns_apod_images_bucket.name
#   }
# }