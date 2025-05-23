# novascope/terraform/backend.tf

terraform {
  backend "gcs" {
    bucket  = "ns-tfstate-sigma-outcome-0522" # 您已创建的用于存储 Terraform 状态的 GCS Bucket 名称
    prefix  = "novascope/terraform.tfstate"     # 状态文件在桶中的路径
  }
}