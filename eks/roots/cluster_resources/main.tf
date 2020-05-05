provider "aws" {
  version = "~> 2.58"
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_auth_token
    load_config_file       = false
  }

  version = "~> 1.1.1"
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_auth_token
  load_config_file       = false
  version                = "~> 1.11"
}

terraform {
  backend "s3" {
    key = "terraform_cbci/cluster_resources/terraform.tfstate"
  }
}

variable "acm_certificate_arn" {
  default = ""
}

variable "autoscaler_repository" {
  default = "us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler"
}

variable "autoscaler_tag" {
  default = "v1.15.6"
}

variable "bucket_name" {}
variable "cluster_name" {}
variable "hibernation_enabled" {
  default = true
}

variable "host_name" {
  default = ""
}

variable "namespace" {
  default = "cloudbees"
}

variable "release_name" {
  default = "cloudbees-ci"
}

resource "kubernetes_namespace" "cloudbees" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "cloudbees" {
  depends_on = [kubernetes_namespace.cloudbees]

  chart      = "cloudbees/cloudbees-core"
  name       = var.release_name
  namespace  = var.namespace
  repository = data.helm_repository.cloudbees.metadata[0].name
  values     = [data.template_file.cloudbees_values.rendered, data.template_file.nginx_values.rendered]
}

resource "helm_release" "cluster_autoscaler" {
  chart     = "stable/cluster-autoscaler"
  name      = "cluster-autoscaler"
  namespace = "kube-system"
  repository = data.helm_repository.stable.metadata[0].name
  values    = [data.template_file.autoscaler_values.rendered]
}

module "iam_auth" {
  providers = { aws = "aws", kubernetes = "kubernetes" }
  source    = "git@github.com:ryecarrigan/terraform-eks-auth.git?ref=v1.0.1"

  cluster_name           = var.cluster_name
  linux_node_role_arns   = [data.terraform_remote_state.eks_cluster.outputs.linux_node_role_arn]
  windows_node_role_arns = [data.terraform_remote_state.eks_cluster.outputs.windows_node_role_arn]
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_region" "current" {}

data "helm_repository" "cloudbees" {
  name = "cloudbees"
  url  = "https://charts.cloudbees.com/public/cloudbees"
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

data "kubernetes_service" "ingress_controller" {
  depends_on = [helm_release.cloudbees]

  metadata {
    namespace = var.namespace
    name      = "${var.release_name}-nginx-ingress-controller"
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
  }
}

data "template_file" "nginx_values" {
  template = file("${path.module}/${local.nginx_values_file}")
  vars = {
    acm_certificate_arn = var.acm_certificate_arn
  }
}

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    key    = "terraform_cbci/cluster_setup/terraform.tfstate"
  }
}

output "ingress_hostname" {
  value = data.kubernetes_service.ingress_controller.load_balancer_ingress[0].hostname
}

locals {
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kubernetes_host        = data.aws_eks_cluster.cluster.endpoint
  nginx_values_file      = (var.acm_certificate_arn == "") ? "http_values.yaml.tpl" : "https_values.yaml.tpl"
}
