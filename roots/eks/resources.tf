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

module "dashboard_acm_cert" {
  source = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = var.dashboard_subdomain
}

module "prometheus_acm_cert" {
  source = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = var.grafana_subdomain
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

module "kubernetes_dashboard" {
  depends_on = [module.alb_controller]
  source     = "../../modules/kubernetes-dashboard"

  host_name             = "${var.dashboard_subdomain}.${var.domain_name}"
  ingress_annotations   = local.alb_annotations
  ingress_class_name    = "alb"
  ingress_redirect_path = local.alb_redirect_path
}

module "prometheus" {
  depends_on = [module.alb_controller]
  source     = "../../modules/prometheus"

  cloudbees_ci_namespace = var.ci_namespace
  host_name              = "${var.grafana_subdomain}.${var.domain_name}"
  ingress_annotations    = local.alb_annotations
  ingress_class_name     = "alb"
  ingress_extra_paths    = local.alb_redirect_path
}

resource "local_file" "token" {
  content         = module.kubernetes_dashboard.token
  file_permission = "0400"
  filename        = "admin-user-token.txt"
}

data "aws_caller_identity" "self" {}
data "aws_region" "this" {}

data "aws_route53_zone" "domain_name" {
  name = var.domain_name
}

locals {
  alb_annotations = <<EOT
alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
alb.ingress.kubernetes.io/inbound-cidrs: ${var.ssh_cidr}
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/tags: ${join(",", local.aws_tags)}
alb.ingress.kubernetes.io/target-type: ip
EOT

  alb_redirect_path = <<EOT
- pathType: ImplementationSpecific
  backend:
    service:
      name: ssl-redirect
      port:
        name: use-annotation
EOT

  aws_account_id = data.aws_caller_identity.self.account_id
  aws_region     = data.aws_region.this.name
  aws_tags       = length(keys(var.extra_tags)) > 0 ? [for k, v in var.extra_tags: "${k}=${v}"]: []
}
