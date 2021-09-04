data "digitalocean_kubernetes_versions" "cluster" {
  version_prefix = var.DIGITALOCEAN_KUBERNETES_VERSION
}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name         = "jazzfunk"
  region       = var.DIGITALOCEAN_REGION
  version      = data.digitalocean_kubernetes_versions.cluster.latest_version
  auto_upgrade = true

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }

  node_pool {
    name       = "ingress"
    size       = "s-2vcpu-4gb"
    node_count = 1
    labels = {
      "role" : "ingress"
    }
  }
}

data "digitalocean_droplet" "ingress" {
  id = digitalocean_kubernetes_cluster.cluster.node_pool[0].nodes[0].droplet_id
}

resource "digitalocean_floating_ip" "ingress" {
  region     = var.DIGITALOCEAN_REGION
  droplet_id = data.digitalocean_droplet.ingress.id
}

resource "cloudflare_record" "cluster" {
  zone_id = local.cloudflare_zone.id
  name    = "cluster"
  type    = "A"
  value   = resource.digitalocean_floating_ip.ingress.ip_address
}
