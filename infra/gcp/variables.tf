variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "deployer_sa_email" {
  description = "Service account email used by Terraform for deployments"
  type        = string
  default     = "817261716888-compute@developer.gserviceaccount.com"
}