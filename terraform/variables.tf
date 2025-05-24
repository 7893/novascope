# novascope/terraform/variables.tf

variable "gcp_project_id" {
  description = "GCP 项目 ID"
  type        = string
  default     = "sigma-outcome"
}

variable "gcp_region" {
  description = "GCP 默认区域"
  type        = string
  default     = "us-central1"
}

variable "cloudflare_account_id" {
  description = "Cloudflare 账户 ID (在 terraform.tfvars 中提供)"
  type        = string
  # 没有默认值，确保从 terraform.tfvars 读取
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token (在 terraform.tfvars 中提供)"
  type        = string
  sensitive   = true
  # 没有默认值，确保从 terraform.tfvars 读取
}

variable "resource_prefix" {
  description = "NovaScope 项目资源的统一前缀"
  type        = string
  default     = "ns"
}

variable "gcs_unified_bucket_name" {
  description = "用于 Terraform 状态和函数源码的统一 GCS Bucket 名称"
  type        = string
  default     = "ns-gcs-unified-sigma-outcome" // 与您已创建的桶名一致
}

variable "tf_state_gcs_prefix" {
  description = "Terraform 状态文件在统一 GCS Bucket 内的前缀"
  type        = string
  default     = "tfstate/novascope"
}

variable "function_source_gcs_prefix" {
  description = "Cloud Functions 源码包在统一 GCS Bucket 内的前缀"
  type        = string
  default     = "sources/functions/" // 确保末尾有斜杠
}

variable "r2_bucket_name_suffix" {
  description = "用于存储 NASA 媒体文件的 Cloudflare R2 Bucket 名称后缀"
  type        = string
  default     = "nasa-media" // 通用名称
}

variable "worker_script_name" {
  description = "Cloudflare Worker 脚本的名称"
  type        = string
  default     = "ns" // 您决定的简化名称
}