locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  namespace   = "kube-system"
  role_name   = substr(local.name_prefix, 0, 38)

  values = yamlencode({
    clusterName = var.cluster_name
    createIngressClassResource = true

    serviceAccount = {
      name = var.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn": module.service_account_role.iam_role_arn
      }
    }
  })
}

module "service_account_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_load_balancer_controller_policy = true
  role_name_prefix                       = local.role_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_arn
      namespace_service_accounts = ["${local.namespace}:${var.service_account_name}"]
    }
  }
}

resource "helm_release" "this" {
  chart      = "aws-load-balancer-controller"
  name       = var.release_name
  namespace  = local.namespace
  repository = "https://aws.github.io/eks-charts"
  values     = [local.values]
  version    = var.chart_version
}
