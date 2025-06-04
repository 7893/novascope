resource "google_secret_manager_secret" "nasa_api_key" {
  secret_id = "ns-nasa-api-key"
  replication {
    auto {}
  }
  labels = {
    purpose = "nasa_api"
    managed_by = "terraform"
  }
}

resource "google_secret_manager_secret" "r2_access_key_id" {
  secret_id = "ns-r2-access-key-id"
  replication {
    auto {}
  }
  labels = {
    purpose = "cloudflare_r2"
    managed_by = "terraform"
  }
}

resource "google_secret_manager_secret" "r2_secret_access_key" {
  secret_id = "ns-r2-secret-access-key"
  replication {
    auto {}
  }
  labels = {
    purpose = "cloudflare_r2"
    managed_by = "terraform"
  }
}

resource "google_secret_manager_secret" "cf_worker_shared_secret" {
  secret_id = "ns-cf-worker-shared-secret"
  replication {
    auto {}
  }
  labels = {
    purpose = "cf_worker_gcp_auth"
    managed_by = "terraform"
  }
}
