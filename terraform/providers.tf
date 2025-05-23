# novascope/terraform/providers.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" // 您可以根据需要锁定更具体的版本
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0" // 您可以根据需要锁定更具体的版本
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "cloudflare" {
  api_token  = var.cloudflare_api_token  // 从 terraform.tfvars 或环境变量读取
  # account_id 通常由 provider 根据 token 推断，或在资源级别通过 var.cloudflare_account_id 指定
}