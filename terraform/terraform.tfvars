# novascope/terraform/terraform.tfvars
# 请用您的真实值替换!
# 此文件不应提交到版本控制 (Git) - 确保它在 .gitignore 中!

# Cloudflare 配置 (必需)
cloudflare_account_id = "ed3e4f0448b71302675f2b436e5e8dd3" // 您提供的 Cloudflare 账户 ID
cloudflare_api_token  = "JjzD9gh9N9uLhbs3T8_UXcnCORVxcNAPhrXZg36t" // 您提供的 Cloudflare API Token

# GCP project_id 和 region 已在 variables.tf 中设置了默认值，除非您想覆盖，否则无需在此处填写。
# gcp_project_id = "sigma-outcome"
# gcp_region     = "us-central1"

# GCS Bucket for Functions Source (variables.tf 中的默认值是 "ns-gcs-func-source-sigma-outcome-0523")
# 如果此名称已被占用，或者您在上次部分apply中创建了不同名称的桶且不想替换，请在这里提供正确的名称。
# gcs_bucket_for_functions_source_name = "ns-gcs-func-source-sigma-outcome-0523"