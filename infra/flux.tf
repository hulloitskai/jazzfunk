locals {
  ssh_known_hosts  = "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="
  flux_target_path = "cluster/flux"
}

data "flux_install" "flux" {
  target_path = local.flux_target_path
}

data "flux_sync" "flux" {
  target_path = local.flux_target_path
  url         = "ssh://git@github.com/${var.GITHUB_OWNER}/${var.GITHUB_REPO}.git"
  branch      = "main"
}

resource "tls_private_key" "flux" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "github_repository" "flux" {
  name = var.GITHUB_REPO
}

resource "github_repository_deploy_key" "flux" {
  title      = "cluster"
  repository = data.github_repository.flux.name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = true
}

resource "github_repository_file" "flux_install" {
  repository = data.github_repository.flux.name
  file       = "cluster/apps/flux-system/gotk-components.yaml"
  content    = data.flux_install.flux.content
  branch     = "main"
}

resource "github_repository_file" "flux_sync" {
  repository = data.github_repository.flux.name
  file       = "cluster/apps/flux-system/gotk-sync.yaml"
  content    = data.flux_sync.flux.content
  branch     = "main"
}

resource "github_repository_file" "kustomize" {
  repository = data.github_repository.flux.name
  file       = "cluster/apps/flux-system/kustomize.yaml"
  content    = data.flux_sync.flux.kustomize_content
  branch     = "main"
}

resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

data "kubectl_file_documents" "flux_install" {
  content = data.flux_install.flux.content
}

data "kubectl_file_documents" "flux_sync" {
  content = data.flux_sync.flux.content
}

locals {
  flux_install = [for v in data.kubectl_file_documents.flux_install.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
  flux_sync = [for v in data.kubectl_file_documents.flux_sync.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
}

resource "kubectl_manifest" "flux_install" {
  for_each   = { for v in local.flux_install : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_namespace.flux_system]
  yaml_body  = each.value
}

resource "kubectl_manifest" "flux_sync" {
  for_each   = { for v in local.flux_sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_namespace.flux_system]
  yaml_body  = each.value
}

resource "kubernetes_secret" "flux" {
  depends_on = [kubectl_manifest.flux_install]

  metadata {
    name      = data.flux_sync.flux.secret
    namespace = data.flux_sync.flux.namespace
  }

  data = {
    identity       = tls_private_key.flux.private_key_pem
    "identity.pub" = tls_private_key.flux.public_key_pem
    known_hosts    = local.ssh_known_hosts
  }
}
