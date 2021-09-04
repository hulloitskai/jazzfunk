terraform {
  required_version = ">= 0.13"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.10"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1"
    }

    flux = {
      source  = "fluxcd/flux"
      version = "~> 0.3"
    }
  }
}

provider "digitalocean" {
  token = var.DIGITALOCEAN_TOKEN
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_TOKEN
}

locals {
  cluster        = digitalocean_kubernetes_cluster.cluster
  cluster_config = local.cluster.kube_config[0]
}

provider "kubernetes" {
  host  = local.cluster.endpoint
  token = local.cluster_config.token
  cluster_ca_certificate = base64decode(
    local.cluster_config.cluster_ca_certificate
  )
}

provider "kubectl" {}
provider "flux" {}

