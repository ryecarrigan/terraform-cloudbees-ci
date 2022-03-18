resource "helm_release" "this" {
  chart      = "aws-ebs-csi-driver"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  values     = [local.helm_values]
  version    = var.release_version
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class": var.is_default
    }
  }

  parameters = {
    encrypted = true
    type      = "gp2"
  }

  storage_provisioner = "ebs.csi.aws.com"
}

resource "aws_iam_policy" "this" {
  name_prefix = "${var.cluster_name}_ebs-csi-driver"
  policy      = file("${path.module}/policy.json")
  tags        = var.extra_tags
}

resource "aws_iam_role" "this" {
  name_prefix = "${var.cluster_name}_ebs-csi-driver"

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
          "${var.oidc_issuer}:sub": "system:serviceaccount:${var.namespace}:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOT

  tags = var.extra_tags
}

resource "aws_iam_role_policy_attachment" "ebs_policy_attachment" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

locals {
  ec2_arn_prefix = "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}"

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

  extra_tags = join("\n", [for k, v in var.extra_tags : "\"${k}\": \"${v}\""])
  helm_values = <<EOT
controller:
  extraVolumeTags:
    ${indent(4, local.extra_tags)}
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.this.arn}
enableVolumeSnapshot: true
image:
  repository: "${local.eks_addon_repository}/eks/aws-ebs-csi-driver"
EOT
}
