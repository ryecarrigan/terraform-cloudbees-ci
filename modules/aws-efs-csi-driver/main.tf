data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values   = ["sts.${var.dns_suffix}"]
      variable = "${var.oidc_issuer}:aud"
    }

    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:${var.service_account_name}"]
      variable = "${var.oidc_issuer}:sub"
    }

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.oidc_issuer}"]
    }
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions   = ["elasticfilesystem:DescribeAccessPoints"]
    effect    = "Allow"
    resources = ["arn:aws:elasticfilesystem:${var.aws_region}:${var.aws_account_id}:access-point/*"]
  }

  statement {
    actions   = ["elasticfilesystem:DescribeFileSystems"]
    effect    = "Allow"
    resources = [aws_efs_file_system.this.arn]
  }

  statement {
    actions   = ["elasticfilesystem:CreateAccessPoint"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["true"]
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
    }
  }
}

locals {
  values = yamlencode({
    controller = {
      serviceAccount = {
        annotations = {
          "eks.${var.dns_suffix}/role-arn" = aws_iam_role.this.arn
        }

        name = var.service_account_name
      }
    }

    image = {
      repository = "${var.eks_addon_repository}/eks/aws-efs-csi-driver"
    }

    storageClasses = [{
      allowVolumeExpansion = true

      annotations = {
        "storageclass.kubernetes.io/is-default-class" = tostring(var.is_default_class)
      }

      name = var.storage_class_name

      parameters = {
        directoryPerms   = "700"
        fileSystemId     = aws_efs_file_system.this.id
        provisioningMode = "efs-ap"
      }
    }]
  })
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = "${var.cluster_name}_${var.release_name}"
}

resource "aws_iam_policy" "this" {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

resource "aws_efs_file_system" "this" {

}

resource "aws_efs_mount_target" "this" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.this.id]
  subnet_id       = var.private_subnet_ids[count.index]
}

resource "aws_security_group" "this" {
  description = "Security group for EFS mount targets in EKS cluster ${var.cluster_name}"
  name        = "${var.cluster_name}-${var.release_name}"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "egress" {
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group_id
  to_port                  = 2049
  type                     = "egress"
}

resource "aws_security_group_rule" "ingress" {
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group_id
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
