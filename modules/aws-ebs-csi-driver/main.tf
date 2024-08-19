locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  namespace   = "kube-system"
  role_name   = substr(local.name_prefix, 0, 38)
  service_account = "ebs-csi-controller-sa"
  volume_tags = {for k, v in var.volume_tags: "tagSpecification_${k}" => "${k}=${v}"}
}

module "service_account_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_ebs_csi_policy = true
  role_name_prefix      = local.role_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_arn
      namespace_service_accounts = ["${local.namespace}:${local.service_account}"]
    }
  }
}

resource "aws_eks_addon" "this" {
  addon_name               = "aws-ebs-csi-driver"
  cluster_name             = var.cluster_name
  service_account_role_arn = module.service_account_role.iam_role_arn
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = merge({
    encrypted = "true"
    type      = "gp2"
  }, local.volume_tags)
}
