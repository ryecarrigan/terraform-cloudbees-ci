data "kubernetes_resource" "crd" {
  for_each   = var.create_service_monitors ? local.this : []
  depends_on = [kubernetes_namespace_v1.this]

  api_version = "apiextensions.k8s.io/v1"
  kind        = "CustomResourceDefinition"

  metadata {
    name = "servicemonitors.monitoring.coreos.com"
  }
}

locals {
  config_map_name         = lookup(lookup(lookup(local.values_yaml, "OperationsCenter", {}), "CasC", {}), "ConfigMapName", "oc-casc-bundle")
  create_bundle           = length(var.bundle_data) != 0
  create_secret           = length(var.secret_data) != 0
  lb_config_name          = "lbconfig-gateway"
  service_account_cjoc    = lookup(lookup(local.values_yaml, "rbac", {}), "serviceAccountName", "cjoc")
  service_account_jenkins = lookup(lookup(local.values_yaml, "rbac", {}), "masterServiceAccountName", "jenkins")
  target_group_name       = "cloudbees-target-group"

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
    },

    pluggable-storage = {
      matchLabels = {
        app = "pluggable-storage-service"
      }
    }
  }

  this        = toset(["this"])
  values_yaml = yamldecode(var.values)
}

resource "kubernetes_namespace_v1" "this" {
  for_each = var.manage_namespace ? local.this : []

  metadata {
    name = var.namespace
    labels = {
      "cloudbees.com/gateway-routes" = "enabled"
    }
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_namespace_v1.this]

  chart      = "cloudbees-core"
  name       = "cloudbees-ci"
  namespace  = var.namespace
  repository = var.chart_repository
  values     = [var.values]
  version    = var.chart_version
}

resource "kubernetes_config_map_v1" "casc_bundle" {
  for_each   = local.create_bundle ? local.this : []
  depends_on = [kubernetes_namespace_v1.this]

  metadata {
    name      = local.config_map_name
    namespace = var.namespace
  }

  data = var.bundle_data
}

resource "kubernetes_secret_v1" "secrets" {
  for_each   = local.create_secret ? local.this : []
  depends_on = [kubernetes_namespace_v1.this]

  metadata {
    name      = var.secret_name
    namespace = var.namespace
  }

  data = var.secret_data
}

resource "kubernetes_role_v1" "secrets" {
  depends_on = [kubernetes_namespace_v1.this]
  for_each   = var.create_secrets_role ? local.this : []

  metadata {
    name      = var.secrets_role_name
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "cjoc" {
  depends_on = [kubernetes_namespace_v1.this]
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

resource "kubernetes_role_binding_v1" "jenkins" {
  depends_on = [kubernetes_namespace_v1.this]
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
    metadata = {
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

resource "kubernetes_manifest" "target_group" {
  for_each = var.create_gateway ? local.this : []

  manifest = {
    apiVersion = "gateway.k8s.aws/v1beta1"
    kind       = "TargetGroupConfiguration"
    metadata = {
      name      = local.target_group_name
      namespace = var.namespace
    }

    spec = {
      defaultConfiguration = {
        targetType = "ip"
        targetGroupAttributes = [
          { key : "stickiness.enabled", value : "true" },
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "load_balancer_configuration" {
  depends_on = [kubernetes_manifest.target_group]
  for_each   = var.create_gateway ? local.this : []

  manifest = {
    apiVersion = "gateway.k8s.aws/v1beta1"
    kind       = "LoadBalancerConfiguration"

    metadata = {
      name      = local.lb_config_name
      namespace = var.namespace
    }

    spec = {
      loadBalancerName = "cloudbees-ci-alb"
      scheme           = "internet-facing"
      tags             = var.tags
      defaultTargetGroupConfiguration = {
        name = local.target_group_name
      }
    }
  }
}

resource "kubernetes_manifest" "gateway" {
  depends_on = [kubernetes_manifest.load_balancer_configuration]
  for_each   = var.create_gateway ? local.this : []

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1",
    kind       = "Gateway",
    metadata = {
      name      = var.gateway_name
      namespace = var.namespace
    },
    spec = {
      gatewayClassName = var.gateway_class_name
      infrastructure = {
        parametersRef = {
          kind  = "LoadBalancerConfiguration"
          name  = local.lb_config_name
          group = "gateway.k8s.aws"
        }
      }

      listeners = [
        {
          name     = "http",
          protocol = "HTTP",
          port     = 80,
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        },
        {
          name     = "https",
          hostname = var.host_name,
          protocol = "HTTPS",
          port     = 443,
          allowedRoutes = {
            namespaces = {
              selector = {
                "matchLabels" = {
                  "cloudbees.com/gateway-routes" = "enabled"
                }
              }
            }
          }
        }
      ]
    }
  }

  wait {
    fields = {
      "status.addresses[0].value" = "*"
    }
  }
}

resource "kubernetes_manifest" "http_route" {
  depends_on = [kubernetes_manifest.gateway]
  for_each   = var.create_gateway ? local.this : []

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1",
    kind       = "HTTPRoute",
    metadata = {
      name      = "https-redirect",
      namespace = var.namespace
    },
    spec = {
      parentRefs = [
        {
          name        = "cloudbees-ci",
          sectionName = "http"
        }
      ],
      rules = [
        {
          filters = [
            {
              type = "RequestRedirect",
              requestRedirect = {
                scheme     = "https",
                statusCode = 301
              }
            }
          ]
        }
      ]
    }
  }
}
