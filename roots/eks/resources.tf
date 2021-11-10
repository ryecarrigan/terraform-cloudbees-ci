module "cd_acm_cert" {
  source = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = var.cd_subdomain
}

module "ci_acm_cert" {
  source = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = var.ci_subdomain
}

module "alb_controller" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/alb-controller"

  aws_region        = local.aws_region
  cluster_name      = var.cluster_name
  extra_tags        = var.extra_tags
  oidc_issuer       = local.oidc_issuer
  oidc_provider_arn = local.oidc_provider_arn
}

module "cluster_autoscaler" {
  source = "../../modules/cluster-autoscaler"

  cluster_name       = var.cluster_name
  kubernetes_version = var.eks_version
  oidc_issuer        = local.oidc_issuer
  oidc_provider_arn  = local.oidc_provider_arn
  worker_asg_arns    = module.cluster.workers_asg_arns
}

module "ebs_driver" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/aws-ebs-csi-driver"

  aws_account_id    = local.aws_account_id
  aws_region        = local.aws_region
  cluster_name      = var.cluster_name
  extra_tags        = var.extra_tags
  oidc_issuer       = local.oidc_issuer
  oidc_provider_arn = local.oidc_provider_arn
}

module "efs_driver" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/aws-efs-csi-driver"

  aws_account_id           = local.aws_account_id
  aws_region               = local.aws_region
  cluster_name             = var.cluster_name
  extra_tags               = var.extra_tags
  oidc_issuer              = local.oidc_issuer
  oidc_provider_arn        = local.oidc_provider_arn
  private_subnet_ids       = module.vpc.private_subnets
  source_security_group_id = module.cluster.worker_security_group_id
  vpc_id                   = module.vpc.vpc_id
}

module "external_dns" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/external-dns-eks"

  cluster_name      = var.cluster_name
  extra_tags        = var.extra_tags
  oidc_issuer       = local.oidc_issuer
  oidc_provider_arn = local.oidc_provider_arn
  route53_zone_id   = data.aws_route53_zone.domain_name.id
}

module "ingress_nginx" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/ingress-nginx"

  acm_certificate_arn = module.cd_acm_cert.certificate_arn
}

resource "kubernetes_config_map" "iam_auth" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOT
- rolearn: ${module.cluster.worker_iam_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOT
  }
}

data "aws_caller_identity" "self" {}
data "aws_region" "this" {}

data "aws_route53_zone" "domain_name" {
  name = var.domain_name
}

locals {
  aws_account_id = data.aws_caller_identity.self.account_id
  aws_region     = data.aws_region.this.name
}
