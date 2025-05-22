terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # 您可以根据需要调整版本约束
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0" # 您可以根据需要调整版本约束
    }
  }
}

# GCP Provider Configuration
# 将在后续步骤中添加项目ID、区域和认证信息
provider "google" {
  # project = "YOUR_GCP_PROJECT_ID"
  # region  = "YOUR_GCP_REGION"
}

# Cloudflare Provider Configuration
# 将在后续步骤中添加 API token 和账户 ID
provider "cloudflare" {
  # api_token = "YOUR_CLOUDFLARE_API_TOKEN"
  # account_id = "YOUR_CLOUDFLARE_ACCOUNT_ID"
}
