locals {
  name_prefix     = "${var.cluster_name}_${var.release_name}"
  namespace       = "kube-system"
  protection      = (var.replication_protection) ? "ENABLED" : "DISABLED"
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

resource "aws_efs_file_system" "this" {
  encrypted = var.encrypt_file_system
  tags = {
    Name = local.name_prefix
  }

  protection {
    replication_overwrite = local.protection
  }

  lifecycle {
    ignore_changes = [protection]
  }
}

resource "aws_efs_mount_target" "this" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.this.id]
  subnet_id       = var.private_subnet_ids[count.index]
}

resource "aws_security_group" "this" {
  description = "Security group for EFS mount targets in EKS cluster ${var.cluster_name}"
  name_prefix = local.name_prefix
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress" {
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = var.node_security_group_id
  source_security_group_id = aws_security_group.this.id
  to_port                  = 2049
  type                     = "egress"
}

resource "aws_security_group_rule" "ingress" {
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.node_security_group_id
  to_port                  = 2049
  type                     = "ingress"
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
    fileSystemId          = aws_efs_file_system.this.id
    provisioningMode      = "efs-ap"
    subPathPattern        = "$${.PVC.name}"
    gid                   = var.storage_class_gid
    uid                   = var.storage_class_uid
  }
}
