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

variable "bucket_name" {}
variable "host_name" {
  default = ""
}

module "cloudbees_ci" {
  providers = { helm = "helm", kubernetes = "kubernetes" }
  source    = "git@github.com:ryecarrigan/terraform-k8s-cloudbees.git?ref=v1.0.0"

  acm_certificate_arn = var.acm_certificate_arn
  host_name           = var.host_name
  hibernation_enabled = true
}

module "cluster_autoscaler" {
  providers = { helm = "helm" }
  source    = "git@github.com:ryecarrigan/terraform-eks-autoscaler.git?ref=v1.0.0"

  aws_region   = data.aws_region.current.name
  cluster_name = local.cluster_name
}

module "iam_auth" {
  providers = { aws = "aws", kubernetes = "kubernetes" }
  source    = "git@github.com:ryecarrigan/terraform-eks-auth.git?ref=v1.0.1"

  cluster_name           = local.cluster_name
  linux_node_role_arns   = [data.terraform_remote_state.eks_cluster.outputs.linux_node_role_arn]
  windows_node_role_arns = [data.terraform_remote_state.eks_cluster.outputs.windows_node_role_arn]
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_region" "current" {}

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    key    = "terraform_cbci/cluster_setup/terraform.tfstate"
  }
}

output "host_name" {
  value = var.host_name
}

output "ingress_hostname" {
  value = module.cloudbees_ci.ingress_hostname
}

locals {
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  cluster_name           = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  kubernetes_host        = data.aws_eks_cluster.cluster.endpoint
}
