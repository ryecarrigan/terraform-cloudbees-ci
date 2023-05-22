resource "kubernetes_namespace" "this" {
  for_each = var.manage_namespace ? local.this : []

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "this" {
  for_each = local.has_license ? local.this : []

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
  namespace  = var.namespace
  repository = "https://charts.cloudbees.com/public/cloudbees"
  values     = concat([local.values], var.values)
  version    = var.chart_version
}

locals {
  has_license = var.license_data != ""
  secret_name = "flow-secret"
  this        = toset(["this"])

  values = <<EOT
flowLicense:
  existingSecret: ${local.secret_name}
EOT
}
