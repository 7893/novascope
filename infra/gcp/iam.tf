
resource "google_service_account" "functions" {
  account_id   = var.functions_sa_name
  display_name = "NovaScope Functions SA"
}

resource "google_project_iam_member" "functions_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.functions.email}"
}

resource "google_project_iam_member" "functions_firestore_access" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.functions.email}"

