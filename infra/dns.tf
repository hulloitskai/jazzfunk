data "cloudflare_zones" "zone" {
  filter {
    name = var.CLOUDFLARE_DOMAIN
  }
}

locals {
  cloudflare_zone = data.cloudflare_zones.zone.zones[0]
}

resource "cloudflare_record" "naked" {
  zone_id = local.cloudflare_zone.id
  name    = "@"
  type    = "CNAME"
  value   = "cluster.${var.CLOUDFLARE_DOMAIN}"
}

resource "cloudflare_record" "www" {
  zone_id = local.cloudflare_zone.id
  name    = "www"
  type    = "CNAME"
  value   = "cluster.${var.CLOUDFLARE_DOMAIN}"
}
