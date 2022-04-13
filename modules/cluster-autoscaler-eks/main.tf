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

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}

locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"

  values = yamlencode({
    autoDiscovery = {
      enabled     = true
      clusterName = var.cluster_name
    }

    awsRegion     = var.aws_region
    cloudProvider = "aws"

    image = {
      tag = "v${var.kubernetes_version}.${var.patch_version}"
    }

    rbac = {
      serviceAccount = {
        name = var.service_account_name
        annotations = {
          "eks.${var.partition_dns}/role-arn" = aws_iam_role.this.arn
        }
      }
    }
  })
}

resource "aws_iam_policy" "this" {
  name_prefix = substr(local.name_prefix, 0, 102)
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = substr(local.name_prefix, 0, 38)
}

resource "aws_iam_role_policy_attachment" "ebs_policy_attachment" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

resource "helm_release" "this" {
  chart      = "cluster-autoscaler"
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  values     = [local.values]
  version    = var.release_version
}
