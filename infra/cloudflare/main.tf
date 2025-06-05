terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0" 
    }
  }
}

provider "cloudflare" {
  api_token  = "fMSkG5FVM8mf5OiwWS3y_-xnNFoaAzKRLRdwRKy9"
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  default     = "ed3e4f0448b71302675f2b436e5e8dd3" 
}

# variable "cloudflare_zone_id" {
#   description = "Cloudflare Zone ID for a custom domain."
#   type        = string
#   # default     = "your_actual_zone_id" 
# }