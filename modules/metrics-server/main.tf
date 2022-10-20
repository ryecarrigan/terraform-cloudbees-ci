locals {
  values = yamlencode({

    apiService = {
      create = true
    }

    hostNetwork = {
      enabled = true
    }

    metrics = {
      enabled = true
    }

  })
}

resource "helm_release" "this" {
  chart      = "metrics-server"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://charts.bitnami.com/bitnami"
  values     = [local.values]
  version    = var.release_version
  replace    = true
}
