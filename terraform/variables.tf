# novascope/terraform/variables.tf

variable "gcp_project_id" {
  description = "您的 GCP 项目 ID"
  type        = string
  default     = "sigma-outcome"
}

variable "gcp_region" {
  description = "您的 GCP 默认区域"
  type        = string
  default     = "us-central1"
}

variable "cloudflare_account_id" {
  description = "您的 Cloudflare 账户 ID (请在 terraform.tfvars 中提供)"
  type        = string
  # 没有默认值，将从 terraform.tfvars 读取
}

variable "cloudflare_api_token" {
  description = "您的 Cloudflare API Token (请在 terraform.tfvars 中提供)"
  type        = string
  sensitive   = true # 标记为敏感数据
  # 没有默认值，将从 terraform.tfvars 读取
}

variable "resource_prefix" {
  description = "NovaScope 项目资源的统一前缀"
  type        = string
  default     = "ns"
}

variable "gcs_bucket_for_functions_source_name" {
  description = "用于存储 Cloud Functions 源码的 GCS Bucket 名称 (需全局唯一)"
  type        = string
  # 基于您上次 apply 时成功创建的桶名，避免不必要的替换
  default     = "ns-gcs-func-source-sigma-outcome-0523" 
}

variable "r2_bucket_name_suffix" {
  description = "用于存储 APOD 图片的 Cloudflare R2 Bucket 名称后缀"
  type        = string
  default     = "apod-images" # 实际桶名将是 ns-r2-apod-images
}