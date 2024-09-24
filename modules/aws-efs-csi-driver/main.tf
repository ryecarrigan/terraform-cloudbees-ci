locals {
  name_prefix     = "${var.cluster_name}_${var.release_name}"
  namespace       = "kube-system"
  role_name       = substr(local.name_prefix, 0, 38)
  service_account = "efs-csi-controller-sa"
}

module "service_account_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_efs_csi_policy = true
  role_name_prefix      = local.role_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_arn
      namespace_service_accounts = ["${local.namespace}:${local.service_account}"]
    }
  }
}

module "efs_file_system" {
  source = "../efs-file-system"

  private_subnet_ids       = var.private_subnet_ids
  source_security_group_id = var.node_security_group_id
  vpc_id                   = var.vpc_id
}

resource "aws_eks_addon" "this" {
  addon_name               = "aws-efs-csi-driver"
  cluster_name             = var.cluster_name
  service_account_role_arn = module.service_account_role.iam_role_arn
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner    = "efs.csi.aws.com"
  volume_binding_mode    = "Immediate"

  parameters = {
    directoryPerms        = "700"
    ensureUniqueDirectory = false
    fileSystemId          = module.efs_file_system.file_system_id
    provisioningMode      = "efs-ap"
    subPathPattern        = "$${.PVC.name}"
    gid                   = var.storage_class_gid
    uid                   = var.storage_class_uid
  }
}
