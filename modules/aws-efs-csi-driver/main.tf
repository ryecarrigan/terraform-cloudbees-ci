resource "helm_release" "this" {
  depends_on = [kubernetes_service_account.this]

  chart      = "aws-efs-csi-driver"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  values     = [local.efs_driver_values]
  version    = var.release_version
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn": aws_iam_role.this.arn
    }

    labels = {
      "app.kubernetes.io/name": var.release_name
    }
  }
}

resource "kubernetes_storage_class" "this" {
  depends_on = [aws_efs_mount_target.this]

  metadata {
    name = var.storage_class_name
  }

  parameters = {
    directoryPerms   = "700"
    fileSystemId     = aws_efs_file_system.this.id
    provisioningMode = "efs-ap"
  }

  storage_provisioner = "efs.csi.aws.com"
}

resource "aws_efs_file_system" "this" {
  tags = var.extra_tags
}

resource "aws_efs_mount_target" "this" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.this.id]
  subnet_id       = var.private_subnet_ids[count.index]
}

resource "aws_security_group" "this" {
  description = "Security group for EFS mount targets"
  name        = "${var.cluster_name}-efs"
  vpc_id      = var.vpc_id

  tags = var.extra_tags
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

resource "aws_iam_policy" "this" {
  name = "${var.cluster_name}_efs-csi-driver"
  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["elasticfilesystem:DescribeAccessPoints"],
      "Resource": "arn:aws:elasticfilesystem:${var.aws_region}:${var.aws_account_id}:access-point/*"
    },
    {
      "Effect": "Allow",
      "Action": ["elasticfilesystem:DescribeFileSystems"],
      "Resource": "${aws_efs_file_system.this.arn}"
    },
    {
      "Effect": "Allow",
      "Action": ["elasticfilesystem:CreateAccessPoint"],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "arn:aws:elasticfilesystem:${var.aws_region}:${var.aws_account_id}:access-point/*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOT

  tags = var.extra_tags
}

resource "aws_iam_role" "this" {
  name_prefix = "${var.cluster_name}_efs-csi-driver"

  assume_role_policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${var.oidc_issuer}:sub": "system:serviceaccount:${var.namespace}:${var.service_account_name}"
        }
      }
    }
  ]
}

EOT

  tags = var.extra_tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

locals {
  efs_driver_values = <<EOT
controller:
  serviceAccount:
    create: false
    name: ${var.service_account_name}
image:
  repository: "${local.eks_addon_repository}/eks/aws-efs-csi-driver"
EOT

  eks_addon_repository = lookup(local.eks_addon_repository_map, var.aws_region)
  eks_addon_repository_map = {
    "af-south-1"     = "877085696533.dkr.ecr.af-south-1.amazonaws.com"
    "ap-east-1"      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com"
    "ap-northeast-1" = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com"
    "ap-northeast-2" = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"
    "ap-northeast-3" = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com"
    "ap-south-1"     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com"
    "ap-southeast-1" = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"
    "ap-southeast-2" = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"
    "ca-central-1"   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com"
    "cn-north-1"     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn"
    "cn-northwest-1" = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn"
    "eu-central-1"   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com"
    "eu-north-1"     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com"
    "eu-south-1"     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com"
    "eu-west-1"      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com"
    "eu-west-2"      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com"
    "eu-west-3"      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com"
    "me-south-1"     = "558608220178.dkr.ecr.me-south-1.amazonaws.com"
    "sa-east-1"      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com"
    "us-east-1"      = "602401143452.dkr.ecr.us-east-1.amazonaws.com"
    "us-east-2"      = "602401143452.dkr.ecr.us-east-2.amazonaws.com"
    "us-gov-east-1"  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com"
    "us-gov-west-1"  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com"
    "us-west-1"      = "602401143452.dkr.ecr.us-west-1.amazonaws.com"
    "us-west-2"      = "602401143452.dkr.ecr.us-west-2.amazonaws.com"
  }
}
