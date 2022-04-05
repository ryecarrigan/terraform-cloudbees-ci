resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "dashboard" {
  depends_on = [kubernetes_namespace.this]

  chart      = "kubernetes-dashboard"
  name       = "kubernetes-dashboard"
  namespace  = var.namespace
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
  values = yamlencode({
    ingress = {
      className = var.ingress_class_name
      enabled   = true
      hosts     = [var.host_name]

      annotations = merge(var.ingress_annotations, {
        "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      })
    }
  })
}

variable "host_name" {}
variable "ingress_annotations" {
  default = {}
  type    = map(string)
}

variable "ingress_redirect_path" {
  default = {}
  type    = any
}

variable "ingress_class_name" {
  type = string
}

variable "namespace" {
  default = "kubernetes-dashboard"
}

