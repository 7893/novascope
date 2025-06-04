resource "google_service_account" "ns_functions_sa" {
  account_id   = "ns-functions"
  display_name = "NovaScope Cloud Functions Service Account"
}

resource "google_project_iam_member" "functions_sa_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.ns_functions_sa.email}"
}
