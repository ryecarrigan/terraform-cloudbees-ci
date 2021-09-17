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

variable "admin_password" {
  default = ""
}

variable "bucket_name" {}
variable "cd_chart_version" {}
variable "ci_chart_version" {}
variable "cloudbees_namespace" {
  default = "cloudbees"
}

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

variable "release_name" {
  default = "cloudbees-sda"
}

resource "helm_release" "cloudbees_ci" {
  timeout = 600

  chart      = "cloudbees/cloudbees-core"
  name       = "${var.release_name}-ci"
  namespace  = data.kubernetes_namespace.cloudbees.metadata[0].name
  repository = data.helm_repository.cloudbees.metadata[0].name
  values     = [data.template_file.cloudbees_ci.rendered]
  version    = var.ci_chart_version
}

variable "cd_namespace" {
  default = "flow"
}

resource "kubernetes_namespace" "cloudbees_cd" {
  metadata {
    name = var.cd_namespace
  }
}

resource "helm_release" "cloudbees_cd" {
  timeout = 1200

  chart      = "cloudbees/cloudbees-flow"
  name       = "${var.release_name}-cd"
  namespace  = kubernetes_namespace.cloudbees_cd.metadata[0].name
  repository = data.helm_repository.cloudbees.metadata[0].name
  values     = [data.template_file.cloudbees_cd.rendered]
  version    = var.cd_chart_version
}

variable "mysql_enabled" {
  default = true
  type    = string
}

resource "kubernetes_namespace" "mysql" {
  count = local.mysql_enabled
  metadata {
    name = "mysql"
  }
}

resource "helm_release" "mysql" {
  count = local.mysql_enabled

  chart      = "bitnami/mysql"
  name       = local.mysql_release
  namespace  = local.mysql_namespace
  repository = data.helm_repository.mysql.metadata[0].name
  values     = [data.template_file.mysql_values.rendered]
}

resource "kubernetes_config_map" "oc_casc_bundle" {
  metadata {
    name      = "oc-casc-bundle"
    namespace = data.kubernetes_namespace.cloudbees.metadata[0].name
  }

  data = {for file in fileset("${path.module}/oc-casc-bundle", "*.{yml,yaml}") : file => file("oc-casc-bundle/${file}")}
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = data.aws_eks_cluster.cluster.name
}

data "helm_repository" "cloudbees" {
  name = "cloudbees"
  url  = "https://charts.cloudbees.com/public/cloudbees"
}

data "helm_repository" "mysql" {
  name = "bitnami"
  url  = "https://charts.bitnami.com/bitnami"
}

data "kubernetes_namespace" "cloudbees" {
  metadata {
    name = var.cloudbees_namespace
  }
}

data "template_file" "cloudbees_ci" {
  template = file("${path.module}/cloudbees_ci.yaml.tpl")
  vars = {
    hibernation_enabled = var.hibernation_enabled
    host_name           = var.host_name
  }
}

data "template_file" "cloudbees_cd" {
  template = file("${path.module}/cloudbees_cd.yaml.tpl")
  vars = {
    admin_password = var.admin_password
    host_name      = var.host_name
    mysql_endpoint = "${local.mysql_release}.${local.mysql_namespace}.svc.cluster.local"
  }
}

data "template_file" "mysql_values" {
  template = file("${path.module}/mysql.yaml.tpl")
  vars = {
    auth_password  = var.admin_password
  }
}

data "terraform_remote_state" "nodes" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    key    = "cloudbees_sda/nodes/terraform.tfstate"
  }
}

locals {
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kube_system            = "kube-system"
  kubernetes_host        = data.aws_eks_cluster.cluster.endpoint
  mysql_enabled          = (var.mysql_enabled == "true") ? 1 : 0
  mysql_namespace        = kubernetes_namespace.mysql[0].metadata[0].name
  mysql_release          = "mysql"
}
