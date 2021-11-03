module "alb_controller" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/alb-controller"

  cluster_name      = var.cluster_name
  extra_tags        = var.extra_tags
  oidc_issuer       = local.oidc_issuer
  oidc_provider_arn = local.oidc_provider_arn
}

module "ebs_driver" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/aws-ebs-csi-driver"

  cluster_name      = var.cluster_name
  extra_tags        = var.extra_tags
  oidc_issuer       = local.oidc_issuer
  oidc_provider_arn = local.oidc_provider_arn
}

module "efs_driver" {
  depends_on = [data.http.wait_for_cluster]
  source     = "../../modules/aws-efs-csi-driver"

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
