resource "cloudflare_workers_script" "frontend_worker" {
  account_id = var.cloudflare_account_id 
  name       = "ns" # 这个名称会用于生成 ns.YOUR_WORKERS_SUBDOMAIN.workers.dev

  # 确保这个路径指向您实际的 Worker 脚本文件
  # 我们之前创建了一个占位符: ../../apps/frontend/src/index.js
  # 当您有了编译后的 TypeScript Worker 代码 (例如 dist/worker.js) 时，应更新此路径
  content    = file("../../apps/frontend/src/index.js") 
  module     = true # 因为 Worker 代码（即使是占位符）使用了 ES module 语法

  # R2 存储桶绑定
  r2_bucket_binding {
    name        = "NASA_MEDIA_BUCKET"                             # 在 Worker 代码中访问此 R2 桶时使用的变量名
    bucket_name = cloudflare_r2_bucket.media_r2_bucket.name # 引用 r2.tf 中定义的 R2 桶
  }

  # Secret 文本绑定 (只定义名称，实际值需要在 Cloudflare Dashboard 或 Wrangler CLI 中安全设置)
  secret_text_binding {
    name = "NS_GCP_API_URL"
    text = "placeholder_gcp_api_url" # Terraform 需要一个占位文本，实际值需另外设置
  }

  secret_text_binding {
    name = "NS_GCP_SHARED_SECRET"
    text = "placeholder_shared_secret" # 占位符
  }
  
  # 普通文本绑定 (用于非敏感配置)
  plain_text_binding {
    name = "NS_R2_BUCKET_NAME"
    text = cloudflare_r2_bucket.media_r2_bucket.name # 直接使用 R2 桶的名称
  }
}

# 对于 *.workers.dev 的路由，通常由 Worker Script 的部署自动处理，
# 特别是当 Worker 的名称 (ns) 与期望的子域名第一部分一致时。
# 如果您的 ns.53.workers.dev 路由没有自动生效，我们才需要显式定义 cloudflare_worker_route。
# resource "cloudflare_worker_route" "frontend_route" {
#   account_id  = var.cloudflare_account_id
#   pattern     = "ns.53.workers.dev/*" 
#   script_name = cloudflare_workers_script.frontend_worker.name
# }

output "worker_url" {
  description = "The expected URL of the deployed Worker script."
  value       = "https://ns.53.workers.dev" # 基于您提供的信息
}