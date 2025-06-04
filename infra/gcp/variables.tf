
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "deployer_sa_email" {
  description = "Service account email used by Terraform for deployments"
  type        = string
  default     = "817261716888-compute@developer.gserviceaccount.com"
}

variable "functions_sa_name" {
  description = "Service account name for Cloud Functions"
  type        = string
  default     = "sa-ns-functions"
}

