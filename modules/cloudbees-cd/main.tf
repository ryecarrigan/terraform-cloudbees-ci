resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "flow-license"
    namespace = kubernetes_namespace.this.metadata.0.name
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
  values     = [local.values]
  version    = var.chart_version
}

locals {
  values = <<EOT
ingress:
  host: ${var.host_name}
  annotations:
    ${indent(4, var.ingress_annotations)}
  class: ${var.ingress_class}

platform: ${var.platform}

server:
  extraEnvs:
  - name: CBF_OC_URL
    value: "${var.ci_oc_url}"
  - name: CBF_SERVER_SDA_MODE
    value: "${var.ci_oc_url != ""}"
  volumesPermissionsInitContainer:
    enabled: false

repository:
  enabled: false

dois:
  credentials:
    adminPassword: ${var.admin_password}

storage:
  volumes:
    serverPlugins:
      storageClass: ${var.rwx_storage_class}

database:
  clusterEndpoint: ${var.database_endpoint}
  dbName: ${var.database_name}
  dbUser: ${var.database_user}
  dbPassword: ${var.database_password}
  dbType: ${var.database_type}
  dbPort: ${var.database_port}
  ${var.database_type == "mysql" ? "mysqlConnector:\n    enabled: true" : ""}

flowCredentials:
  adminPassword: ${var.admin_password}

flowLicense:
  existingSecret: ${kubernetes_secret.this.metadata.0.name}

nginx-ingress:
  enabled: false

EOT
}
