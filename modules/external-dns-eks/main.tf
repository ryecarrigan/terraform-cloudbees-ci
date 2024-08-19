data "aws_route53_zone" "this" {
  zone_id = var.route53_zone_id
}

locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  namespace   = "kube-system"
  role_name   = substr(local.name_prefix, 0, 38)

  values = yamlencode({
    extraArgs = ["--zone-id-filter=${data.aws_route53_zone.this.id}"]

    provider = {
      name = "aws"
    }

    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn": module.service_account_role.iam_role_arn
      }

      name = var.service_account_name
    }
  })
}

module "service_account_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${var.route53_zone_id}"]
  role_name_prefix              = local.role_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_arn
      namespace_service_accounts = ["${local.namespace}:${var.service_account_name}"]
    }
  }
}

resource "helm_release" "this" {
  chart      = "external-dns"
  name       = var.release_name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/external-dns"
  values     = [local.values]
  version    = var.chart_version
}
