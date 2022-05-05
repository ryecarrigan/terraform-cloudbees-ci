data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:${var.service_account_name}"]
      variable = "${var.oidc_issuer}:sub"
    }

    principals {
      type        = "Federated"
      identifiers = ["arn:${var.partition_id}:iam::${var.aws_account_id}:oidc-provider/${var.oidc_issuer}"]
    }
  }
}

locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"

  values = yamlencode({
    controller = {
      serviceAccount = {
        annotations = {
          "eks.${var.partition_dns}/role-arn" = aws_iam_role.this.arn
        }

        name = var.service_account_name
      }
    }

    storageClasses = [{
      allowVolumeExpansion = true

      name = var.storage_class_name

      parameters = {
        directoryPerms   = "700"
        fileSystemId     = aws_efs_file_system.this.id
        provisioningMode = "efs-ap"
      }
    }]
  })
}

resource "aws_iam_policy" "this" {
  name_prefix = substr(local.name_prefix, 0, 102)
  policy      = file("${path.module}/policy.json")
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = substr(local.name_prefix, 0, 38)
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
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

resource "helm_release" "this" {
  chart      = "aws-efs-csi-driver"
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  values     = [local.values]
  version    = var.release_version
}
