variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "functions_sa_name" {
  description = "Service account name for Cloud Functions"
  type        = string
  default     = "sa-ns-functions"
}
