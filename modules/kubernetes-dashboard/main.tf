resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "dashboard" {
  chart      = "kubernetes-dashboard"
  name       = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.this.metadata.0.name
  repository = "https://kubernetes.github.io/dashboard/"
  values     = [local.values]
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = "admin-user"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata.0.name
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "this" {
  depends_on = [kubernetes_service_account.this]
  metadata {
    name      = kubernetes_service_account.this.default_secret_name
    namespace = "kube-system"
  }
}

locals {
  values = <<EOT
ingress:
  enabled: true
  className: ${var.ingress_class_name}
  hosts:
    - ${var.host_name}
  annotations:
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    ${indent(4, var.ingress_annotations)}
  customPaths:
    ${indent(4, var.ingress_redirect_path)}
    - pathType: ImplementationSpecific
      backend:
        service:
          name: kubernetes-dashboard
          port:
            name: https
EOT
}

variable "host_name" {}
variable "ingress_annotations" {}
variable "ingress_redirect_path" {}
variable "ingress_class_name" {}
variable "namespace" {
  default = "kubernetes-dashboard"
}

