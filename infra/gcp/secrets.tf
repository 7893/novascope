resource "google_secret_manager_secret" "nasa_api_key" {
  secret_id = "ns-sm-nasa-api-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "r2_access_key_id" {
  secret_id = "ns-sm-r2-access-key-id"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "r2_secret_access_key" {
  secret_id = "ns-sm-r2-secret-access-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "cf_worker_shared_secret" {
  secret_id = "ns-sm-shared-auth-token"
  replication {
    auto {}
  }
}
