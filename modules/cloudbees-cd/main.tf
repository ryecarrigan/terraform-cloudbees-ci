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
  enabled: true
  class: ${var.ingress_class}
  host: ${var.host_name}
  annotations:
    ${indent(4, var.ingress_annotations)}

platform: ${var.platform}

server:
  extraEnvs:
  - name: CBF_OC_URL
    value: "${var.ci_host_name}/cjoc"
  - name: CBF_SERVER_SDA_MODE
    value: "true"
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
  clusterEndpoint: ${var.mysql_endpoint}
  dbName: ${var.mysql_database}
  dbUser: ${var.mysql_user}
  dbPassword: ${var.mysql_password}
  dbType: mysql
  dbPort: 3306
  mysqlConnector:
    enabled: true

flowCredentials:
  adminPassword: ${var.admin_password}

flowLicense:
  existingSecret: ${kubernetes_secret.this.metadata.0.name}

EOT
}
