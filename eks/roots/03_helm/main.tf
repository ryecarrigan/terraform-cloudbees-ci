terraform {
  backend "s3" {
    key = "cloudbees_sda/helm/terraform.tfstate"
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

variable "admin_password" {
  default = ""
}

variable "autoscaler_repository" {
  default = "us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler"
}

variable "autoscaler_tag" {
  default = "v1.18.3"
}

variable "bucket_name" {}
variable "chart_version" {}
variable "cluster_name" {}
variable "extra_tags" {
  default = {}
  type    = map(string)
}

variable "hibernation_enabled" {
  default = true
}

variable "host_name" {
  default = ""
}

variable "agent_namespace" {
  default = "agents"
}

variable "release_name" {
  default = "cloudbees-ci"
}

resource "helm_release" "cjoc" {
  depends_on = [helm_release.ingress_nginx]

  chart      = "cloudbees/cloudbees-sda"
  name       = var.release_name
  namespace  = local.cloudbees_namespace
  repository = data.helm_repository.cloudbees.metadata[0].name
  values     = [data.template_file.cloudbees_values.rendered, file("cloudbees.yaml")]
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
  chart      = "ingress-nginx/ingress-nginx"
  name       = "ingress-nginx"
  namespace  = local.nginx_namespace
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

module "eks_efs_csi" {
  source = "../../modules/terraform-eks-efs"

  cluster_name        = var.cluster_name
  subnet_ids          = local.subnet_ids
  node_role_ids       = local.node_role_ids
  node_security_group = local.node_security_group
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
    namespace = local.nginx_namespace
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
    admin_password      = var.admin_password
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

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    key    = "cloudbees_sda/cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "nodes" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    key    = "cloudbees_sda/nodes/terraform.tfstate"
  }
}

output "ingress_hostname" {
  value = data.kubernetes_service.ingress_controller.load_balancer_ingress[0].hostname
}

locals {
  cloudbees_namespace    = data.terraform_remote_state.nodes.outputs.cloudbees_namespace
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kube_system            = "kube-system"
  kubernetes_host        = data.aws_eks_cluster.cluster.endpoint
  nginx_namespace        = data.terraform_remote_state.nodes.outputs.nginx_namespace
  node_role_ids          = toset(data.terraform_remote_state.nodes.outputs.node_role_ids)
  node_security_group    = data.terraform_remote_state.eks_cluster.outputs.node_security_group_id
  protocol               = (var.acm_certificate_arn == "") ? "http" : "https"
  subnet_ids             = toset(data.terraform_remote_state.eks_cluster.outputs.private_subnet_ids)
}
