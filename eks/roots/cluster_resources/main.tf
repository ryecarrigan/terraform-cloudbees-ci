terraform {
  backend "s3" {
    key = "cloudbees_ci/cluster_resources/terraform.tfstate"
  }
}

provider "aws" {}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_auth_token
    load_config_file       = false
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_auth_token
  load_config_file       = false
}

variable "acm_certificate_arn" {
  default = ""
}

variable "autoscaler_repository" {
  default = "us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler"
}

variable "autoscaler_tag" {
  default = "v1.17.3"
}

variable "bucket_name" {}
variable "chart_version" {}
variable "cluster_name" {}
variable "hibernation_enabled" {
  default = true
}

variable "host_name" {
  default = ""
}

variable "agent_namespace" {
  default = "agents"
}

variable "oc_namespace" {
  default = "cjoc"
}

variable "controller_namespaces" {
  default = []
  type    = set(string)
}

variable "nginx_namespace" {
  default = "ingress-nginx"
}

variable "release_name" {
  default = "cloudbees-ci"
}

resource "kubernetes_namespace" "cjoc" {
  metadata {
    name = var.oc_namespace
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.nginx_namespace
  }
}

resource "helm_release" "cjoc" {
  depends_on = [kubernetes_namespace.cjoc, helm_release.ingress_nginx]

  chart      = "cloudbees/cloudbees-core"
  name       = var.release_name
  namespace  = kubernetes_namespace.cjoc.metadata[0].name
  repository = data.helm_repository.cloudbees.metadata[0].name
  values     = [data.template_file.cloudbees_values.rendered]
  version    = var.chart_version
}

resource "helm_release" "cluster_autoscaler" {
  chart      = "autoscaler/cluster-autoscaler"
  name       = "cluster-autoscaler"
  namespace  = local.kube_system
  repository = data.helm_repository.autoscaler.metadata[0].name
  values     = [data.template_file.autoscaler_values.rendered]
}

resource "helm_release" "ingress_nginx" {
  depends_on = [kubernetes_namespace.ingress_nginx]

  chart      = "ingress-nginx/ingress-nginx"
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  repository = data.helm_repository.ingress_nginx.metadata[0].name
  values     = [data.template_file.nginx_values.rendered]
  version    = "3.1.0"
}

resource "helm_release" "node_termination_handler" {
  chart      = "eks/aws-node-termination-handler"
  name       = "aws-node-termination-handler"
  namespace  = local.kube_system
  repository = data.helm_repository.eks.metadata[0].name
}

module "controller_namespaces" {
  for_each = var.controller_namespaces
  source   = "git@github.com:ryecarrigan/terraform-cbci-namespace.git?ref=v2.0.0"

  host_name             = var.host_name
  master_namespace_name = each.value
  oc_namespace_name     = var.oc_namespace
  release_name          = each.value
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_region" "current" {}

data helm_repository "autoscaler" {
  name = "autoscaler"
  url  = "https://kubernetes.github.io/autoscaler"
}

data "helm_repository" "cloudbees" {
  name = "cloudbees"
  url  = "https://charts.cloudbees.com/public/cloudbees"
}

data "helm_repository" "eks" {
  name = "eks"
  url  = "https://aws.github.io/eks-charts"
}

data "helm_repository" "ingress_nginx" {
  name = "ingress-nginx"
  url  = "https://kubernetes.github.io/ingress-nginx"
}

data "kubernetes_service" "ingress_controller" {
  depends_on = [helm_release.ingress_nginx]

  metadata {
    namespace = var.nginx_namespace
    name      = "ingress-nginx-controller"
  }
}

data "template_file" "autoscaler_values" {
  template = file("${path.module}/autoscaler_values.yaml.tpl")
  vars = {
    aws_region       = data.aws_region.current.name
    cluster_name     = var.cluster_name
    image_repository = var.autoscaler_repository
    image_tag        = var.autoscaler_tag
  }
}

data "template_file" "cloudbees_values" {
  template = file("${path.module}/cloudbees_values.yaml.tpl")
  vars = {
    hibernation_enabled = var.hibernation_enabled
    host_name           = var.host_name
    protocol            = local.protocol
  }
}

data "template_file" "nginx_values" {
  template = file("${path.module}/${local.protocol}_values.yaml.tpl")
  vars = {
    acm_certificate_arn = var.acm_certificate_arn
  }
}

output "ingress_hostname" {
  value = data.kubernetes_service.ingress_controller.load_balancer_ingress[0].hostname
}

locals {
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kube_system            = "kube-system"
  kubernetes_host        = data.aws_eks_cluster.cluster.endpoint
  protocol               = (var.acm_certificate_arn == "") ? "http" : "https"
}
