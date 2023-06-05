data "kubernetes_resource" "crd" {
  for_each   = var.create_service_monitors ? local.this : []
  depends_on = [kubernetes_namespace.this]

  api_version = "apiextensions.k8s.io/v1"
  kind        = "CustomResourceDefinition"

  // noinspection HCLUnknownBlockType
  metadata {
    name = "servicemonitors.monitoring.coreos.com"
  }
}

locals {
  config_map_name = lookup(lookup(lookup(local.values_yaml, "OperationsCenter", {}), "CasC", {}), "ConfigMapName", "oc-casc-bundle")
  create_bundle = length(var.bundle_data) != 0
  create_secret = length(var.secret_data) != 0
  service_account_cjoc = lookup(lookup(local.values_yaml, "rbac", {}), "serviceAccountName", "cjoc")
  service_account_jenkins = lookup(lookup(local.values_yaml, "rbac", {}), "masterServiceAccountName", "jenkins")

  service_monitors = {
    cjoc = {
      matchLabels = {
        "app.kubernetes.io/name" = "cloudbees-core"
      }
    },

    controllers = {
      matchExpressions = [{
        key      = "com.cloudbees.cje.type"
        operator = "Exists"
      }]
    }
  }

  this = toset(["this"])
  values_yaml = yamldecode(var.values)
}

resource "kubernetes_namespace" "this" {
  for_each = var.manage_namespace ? local.this : []

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_namespace.this]

  chart      = "cloudbees-core"
  name       = "cloudbees-ci"
  namespace  = var.namespace
  repository = var.chart_repository
  values     = [var.values]
  version    = var.chart_version
}

resource "kubernetes_config_map" "casc_bundle" {
  for_each   = local.create_bundle ? local.this : []
  depends_on = [kubernetes_namespace.this]

  metadata {
    name      = local.config_map_name
    namespace = var.namespace
  }

  data = var.bundle_data
}

resource "kubernetes_secret" "secrets" {
  for_each   = local.create_secret ? local.this : []
  depends_on = [kubernetes_namespace.this]

  metadata {
    name      = var.secret_name
    namespace = var.namespace
  }

  data = var.secret_data
}

resource "kubernetes_role" "secrets" {
  depends_on = [kubernetes_namespace.this]
  for_each   = var.create_secrets_role ? local.this : []

  metadata {
    name      = var.secrets_role_name
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "cjoc" {
  depends_on = [kubernetes_namespace.this]
  for_each   = var.create_secrets_role ? local.this : []

  metadata {
    name      = local.service_account_cjoc
    namespace = var.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.secrets_role_name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_cjoc
    namespace = var.namespace
  }
}

resource "kubernetes_role_binding" "jenkins" {
  depends_on = [kubernetes_namespace.this]
  for_each   = var.create_secrets_role ? local.this : []

  metadata {
    name      = local.service_account_jenkins
    namespace = var.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.secrets_role_name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_jenkins
    namespace = var.namespace
  }
}

resource "kubernetes_manifest" "service_monitor" {
  for_each   = { for k, v in local.service_monitors : k => v if var.create_service_monitors }
  depends_on = [data.kubernetes_resource.crd]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata   = {
      labels    = { release = "prometheus" }
      name      = each.key
      namespace = var.namespace
    }

    spec = {
      endpoints = [{
        interval    = "30s"
        port        = "http"
        relabelings = var.prometheus_relabelings
      }]

      namespaceSelector = {
        matchNames = [var.namespace]
      }

      selector = each.value
    }
  }
}
