resource "cloudflare_r2_bucket" "media_r2_bucket" {
  account_id = var.cloudflare_account_id # 引用 main.tf 中定义的变量
  name       = "ns-nasa"                 # 符合命名规范
  # location_hint = "auto" # Cloudflare 会自动选择最佳位置，或者您可以指定
}

output "r2_bucket_name" {
  description = "The name of the R2 bucket."
  value       = cloudflare_r2_bucket.media_r2_bucket.name
}