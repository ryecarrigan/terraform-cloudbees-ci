resource "kubernetes_namespace" "this" {
  metadata {
    name = "mysql"
  }
}

resource "helm_release" "this" {
  chart      = "mysql"
  name       = var.release_name
  namespace  = var.namespace_name
  repository = "https://charts.bitnami.com/bitnami"
  values     = [local.helm_values]
  version    = var.chart_version

  set {
    name  = "auth.username"
    value = var.user_name
  }

  set {
    name  = "auth.password"
    value = var.password
  }

  set {
    name  = "auth.rootPassword"
    value = var.root_password
  }
}

locals {
  helm_values = <<EOT
initdbScripts:
  initdb.sql: |
    CREATE DATABASE ${var.database_name} CHARACTER SET utf8 COLLATE utf8_general_ci;
    CREATE DATABASE ${var.database_name}_upgrade CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT ALL PRIVILEGES ON `${var.database_name}%`.* TO '${var.user_name}'@'%';
EOT
}
