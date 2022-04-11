resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_namespace.this]

  chart      = "kube-prometheus-stack"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values     = [local.values]
}

locals {
  values = yamlencode({
    grafana = {
      defaultDashboardsTimezone = "America/New_York"
      ingress = {
        annotations      = var.ingress_annotations
        enabled          = true
        extraPaths       = var.ingress_extra_paths
        hosts            = [var.host_name]
        ingressClassName = var.ingress_class_name
      }
    }
  })
}
