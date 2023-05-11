resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = local.secret_name
    namespace = var.namespace
  }

  data = {
    CBF_LICENSE = var.license_data
  }
}

resource "helm_release" "this" {
  timeout = 1800
  wait    = false

  chart      = "cloudbees-flow"
  name       = var.release_name
  namespace  = kubernetes_namespace.this.metadata.0.name
  repository = "https://charts.cloudbees.com/public/cloudbees"
  values     = concat([local.values], var.values)
  version    = var.chart_version
}

locals {
  secret_name = "flow-secret"

  values = <<EOT
flowLicense:
  existingSecret: ${local.secret_name}
EOT
}
