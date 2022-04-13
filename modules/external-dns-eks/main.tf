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
    actions   = ["route53:ChangeResourceRecordSets"]
    effect    = "Allow"
    resources = [data.aws_route53_zone.this.arn]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_route53_zone" "this" {
  zone_id = var.route53_zone_id
}

locals {
  values = yamlencode({
    provider = "aws"

    serviceAccount = {
      annotations = {
        "eks.${var.partition_dns}/role-arn": aws_iam_role.this.arn
      }

      name = var.service_account_name
    }

    zoneIdFilters = [data.aws_route53_zone.this.id]
  })
}

resource "aws_iam_policy" "this" {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = "${var.cluster_name}_${var.release_name}"
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

resource "helm_release" "this" {
  chart      = "external-dns"
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://charts.bitnami.com/bitnami"
  values     = [local.values]
  version    = var.release_version
}
