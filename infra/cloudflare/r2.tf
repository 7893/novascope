resource "cloudflare_r2_bucket" "ns_nasa" {
  account_id = var.cloudflare_account_id
  name       = "ns-nasa"
}
