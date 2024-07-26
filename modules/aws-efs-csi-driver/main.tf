locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"
}

resource "aws_iam_role" "this" {
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [{
      "Effect" = "Allow",
      "Principal" = {
        "Federated": var.oidc_provider_arn
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition" = {
        "StringLike" = {
          "${var.oidc_issuer}:sub" = "system:serviceaccount:kube-system:efs-csi-*",
          "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  name_prefix = substr(local.name_prefix, 0, 38)
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.this.name
}

resource "aws_efs_file_system" "this" {
  encrypted = var.encrypt_file_system
  tags = {
    Name = local.name_prefix
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
  depends_on = [aws_iam_role_policy_attachment.this]

  addon_name               = "aws-efs-csi-driver"
  cluster_name             = var.cluster_name
  service_account_role_arn = aws_iam_role.this.arn
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner    = "efs.csi.aws.com"
  volume_binding_mode    = "Immediate"

  parameters = {
    directoryPerms   = "700"
    fileSystemId     = aws_efs_file_system.this.id
    provisioningMode = "efs-ap"
    reuseAccessPoint = true
    subPathPattern   = "$${.PVC.name}"
    uid              = var.storage_class_uid
  }
}
