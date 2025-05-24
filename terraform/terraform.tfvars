# novascope/terraform/terraform.tfvars
# 请用您的真实值替换!
# 此文件不应提交到版本控制 (Git) - 确保它在 .gitignore 中!

cloudflare_account_id = "ed3e4f0448b71302675f2b436e5e8dd3"
cloudflare_api_token  = "JjzD9gh9N9uLhbs3T8_UXcnCORVxcNAPhrXZg36t"

# 如果 variables.tf 中 gcs_unified_bucket_name 的默认值 "ns-gcs-unified-sigma-outcome"
# 与您实际创建的桶名不一致（例如因为全局名称冲突而手动改名了），
# 或者您想使用一个不同的名称，请在此处取消注释并修改：
# gcs_unified_bucket_name = "your-actual-unified-bucket-name"

# 其他变量使用 variables.tf 中的默认值。