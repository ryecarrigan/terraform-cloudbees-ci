locals {
  namespace_name = kubernetes_namespace.this.metadata[0].name
  secret_name    = kubernetes_secret.this.metadata[0].name
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = local.namespace_name
    namespace = local.namespace_name
  }

  data = {
    CBF_LICENSE = var.license_data
  }
}

resource "helm_release" "this" {
  timeout = 1800

  chart      = "cloudbees-flow"
  name       = var.release_name
  namespace  = local.namespace_name
  repository = "https://charts.cloudbees.com/public/cloudbees"
  values     = [file("${path.module}/values.yaml"), local.extra_envs, local.ingress_annotations]
  version    = var.chart_version

  set {
    name  = "database.clusterEndpoint"
    value = var.mysql_endpoint
  }

  set {
    name  = "database.dbName"
    value = var.mysql_database
  }

  set {
    name  = "database.dbUser"
    value = var.mysql_user
  }

  set {
    name  = "database.dbPassword"
    value = var.mysql_password
  }

  set {
    name  = "dois.credentials.adminPassword"
    value = var.admin_password
  }

  set {
    name  = "flowCredentials.adminPassword"
    value = var.admin_password
  }

  set {
    name  = "flowLicense.existingSecret"
    value = local.secret_name
  }

  set {
    name  = "ingress.host"
    value = var.host_name
  }

  set {
    name  = "storage.volumes.serverPlugins.storageClass"
    value = var.rwx_storage_class
  }
}

locals {
  extra_envs = <<EOT
server:
  extraEnvs:
  - name: CBF_OC_URL
    value: "${var.ci_host_name}/cjoc"
  - name: CBF_SERVER_SDA_MODE
    value: "true"
EOT

  ingress_annotations = <<EOT
ingress:
  annotations:
    kubernetes.io/ingress.class: ${var.ingress_class}
EOT
}
