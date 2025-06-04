variable "gcp_project_id" {
  description = "GCP 项目ID"
  type        = string
}

variable "gcp_region" {
  description = "默认区域"
  type        = string
  default     = "us-central1"
}
