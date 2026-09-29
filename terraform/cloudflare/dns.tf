data "cloudflare_zone" "lynggaardjensen" {
  filter = {
    name = "lynggaardjensen.com"
  }
}

locals {
  dns_records = {
    "controlplane-01" = "192.168.1.15"
    "kubernetes"      = "192.168.1.15"
    "pihole"          = "192.168.1.3"
    "plex"            = "192.168.1.8"
    "pve1"            = "192.168.1.2"
    "pve2"            = "192.168.1.21"
    "pve3"            = "192.168.1.22"
    "tailscale"       = "192.168.1.9"
    "unifi"           = "192.168.1.4"
  }
}

resource "cloudflare_dns_record" "records" {
  for_each = local.dns_records

  zone_id = data.cloudflare_zone.lynggaardjensen.id
  name    = each.key
  type    = "A"
  ttl     = 300
  content = each.value
  proxied = false
}
