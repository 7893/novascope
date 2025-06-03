resource "cloudflare_worker_script" "ns" {
  name    = "ns"
  content = file("${path.module}/../../apps/frontend/dist/worker.js")
}

resource "cloudflare_worker_route" "ns_dev_route" {
  zone_id     = var.cloudflare_zone_id
  pattern     = "ns.${var.cloudflare_subdomain}.workers.dev/*"
  script_name = cloudflare_worker_script.ns.name
}
