locals {
  values = yamlencode({
    args = ["--kubelet-insecure-tls"]
  })
}

resource "helm_release" "this" {
  chart      = "metrics-server"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  values     = [local.values]
  version    = var.release_version
  replace    = true
}
