# novascope/terraform/backend.tf

terraform {
  backend "gcs" {
    bucket  = "ns-gcs-unified-sigma-outcome" // 指向您已创建的统一 GCS 桶名称
    prefix  = "tfstate/novascope"            // 状态文件在此桶内的路径
  }
}