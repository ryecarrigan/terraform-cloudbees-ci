resource "helm_release" "this" {
  chart      = "cluster-autoscaler"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://kubernetes.github.io/autoscaler"
  version    = var.release_version

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "autoDiscovery.enabled"
    value = true
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.this.name
  }

  set {
    name  = "image.tag"
    value = "v${var.kubernetes_version}.${var.patch_version}"
  }

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = false
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = var.service_account_name
  }
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

resource "aws_iam_policy" "this" {
  name_prefix = "${var.cluster_name}_cluster-autoscaler"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup"
      ],
      "Resource": [${local.asg_arn_strings}],
      "Condition": {
        "StringEquals": {
          "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
          "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned"
        }
      }
    }
  ]
}
EOT
}

resource "aws_iam_role" "this" {
  name_prefix = "${var.cluster_name}_cluster-autoscaler"

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
}

resource "aws_iam_role_policy_attachment" "ebs_policy_attachment" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

data "aws_region" "this" {}

locals {
  asg_arn_strings = join(",\n        ", [for arn in var.worker_asg_arns : "\"${arn}\""])
}
