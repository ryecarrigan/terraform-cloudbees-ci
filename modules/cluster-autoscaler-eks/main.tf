locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  namespace   = "kube-system"
  role_name   = substr(local.name_prefix, 0, 38)

  values = yamlencode({
    autoDiscovery = {
      enabled     = true
      clusterName = var.cluster_name
    }

    awsRegion     = var.aws_region
    cloudProvider = "aws"

    image = {
      tag = var.image_tag
    }

    rbac = {
      serviceAccount = {
        name = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = module.service_account_role.iam_role_arn
        }
      }
    }
  })
}

data "aws_region" "this" {}

module "service_account_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.cluster_name]
  role_name_prefix                 = local.role_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_arn
      namespace_service_accounts = ["${local.namespace}:${var.service_account_name}"]
    }
  }
}

resource "helm_release" "this" {
  chart      = "cluster-autoscaler"
  name       = var.release_name
  namespace  = local.namespace
  repository = "https://kubernetes.github.io/autoscaler"
  values     = [local.values]
  version    = var.release_version
}
