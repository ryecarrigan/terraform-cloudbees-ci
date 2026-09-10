provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_auth_token
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_auth_token
  }
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = local.cluster_name
}

data "aws_region" "current" {}

data "aws_route53_zone" "domain" {
  name = var.domain_name
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket       = var.backend_bucket
    key          = "terraform-cloudbees-ci/eks-core/terraform.tfstate"
    use_lockfile = true
  }
}

locals {
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_region             = data.aws_region.current.region
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_endpoint       = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  cluster_name           = data.terraform_remote_state.eks.outputs["cluster_name"]
  ingress_class_name     = "alb"
  node_security_group_id = data.terraform_remote_state.eks.outputs["node_security_group_id"]
  controllers_role_name  = substr("${local.cluster_name}-controllers", 0, 38)
  oidc_provider_arn      = data.terraform_remote_state.eks.outputs["oidc_provider_arn"]
  private_subnet_ids     = data.terraform_remote_state.eks.outputs["private_subnet_ids"]
  this                   = toset(["this"])
  vpc_id                 = data.terraform_remote_state.eks.outputs["vpc_id"]

  alb_annotations = {
    "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
    "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
    "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
    "alb.ingress.kubernetes.io/tags"                 = join(",", [for k, v in var.tags : "${k}=${v}"])
    "alb.ingress.kubernetes.io/target-type"          = "ip"
  }

  alb_redirect_path = {
    pathType = "ImplementationSpecific"
    backend = {
      service = {
        name = "ssl-redirect"
        port = {
          name = "use-annotation"
        }
      }
    }
  }

  cluster_autoscaler_tag = var.cluster_autoscaler_tag != "" ? var.cluster_autoscaler_tag : "v${var.kubernetes_version}.0"
}

################################################################################
# AWS resources
################################################################################
module "acm_certificate" {
  for_each = var.create_acm_certificate ? local.this : []
  source   = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = "*"
}

module "pluggable_storage" {
  for_each = var.create_pluggable_storage_bucket ? local.this : []
  source   = "../../modules/cloudbees-ci-s3"

  bucket_name          = "${local.cluster_name}-pluggable-storage"
  cluster_name         = local.cluster_name
  namespace            = var.ci_namespace
  service_account_name = "pluggable-storage-service"
}

module "workspace_caching" {
  for_each = var.create_workspace_caching_bucket ? local.this : []
  source   = "../../modules/cloudbees-ci-s3"

  bucket_name        = "${local.cluster_name}-workspace-cache"
  cluster_name       = local.cluster_name
  instance_role_name = local.controllers_role_name
  namespace          = var.ci_namespace
}


################################################################################
# Kubernetes resources
################################################################################

module "aws_load_balancer_controller" {
  depends_on = [module.acm_certificate]
  source     = "../../modules/aws-load-balancer-controller"

  cluster_name = local.cluster_name
  oidc_arn     = local.oidc_provider_arn
}

module "cluster_autoscaler" {
  source = "../../modules/cluster-autoscaler-eks"

  aws_region   = local.aws_region
  cluster_name = local.cluster_name
  image_tag    = local.cluster_autoscaler_tag
  oidc_arn     = local.oidc_provider_arn
}

module "ebs_driver" {
  source = "../../modules/aws-ebs-csi-driver"

  cluster_name = local.cluster_name
  oidc_arn     = local.oidc_provider_arn
  volume_tags  = var.tags
}

module "efs_driver" {
  source = "../../modules/aws-efs-csi-driver"

  cluster_name            = local.cluster_name
  ensure_unique_directory = var.ensure_unique_directory
  node_security_group_id  = local.node_security_group_id
  oidc_arn                = local.oidc_provider_arn
  private_subnet_ids      = local.private_subnet_ids
  sub_path_pattern        = "$${.PVC.name}"
  vpc_id                  = local.vpc_id
}

module "external_dns" {
  source = "../../modules/external-dns-eks"

  aws_account_id  = local.aws_account_id
  cluster_name    = local.cluster_name
  oidc_arn        = local.oidc_provider_arn
  route53_zone_id = data.aws_route53_zone.domain.id
}

module "prometheus" {
  for_each = var.install_prometheus ? local.this : []
  source   = "../../modules/prometheus"

  host_name           = "${var.grafana_subdomain}.${var.domain_name}"
  ingress_annotations = local.alb_annotations
  ingress_class_name  = local.ingress_class_name
  ingress_extra_paths = [local.alb_redirect_path]
  storage_class_name  = module.ebs_driver.storage_class_name
}

module "cluster_metrics" {
  source = "../../modules/metrics-server"
}

module "velero" {
  for_each = var.install_velero ? local.this : []
  source   = "../../modules/velero-aws"

  cluster_name = local.cluster_name
  oidc_arn     = local.oidc_provider_arn
}
