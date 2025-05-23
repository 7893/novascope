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