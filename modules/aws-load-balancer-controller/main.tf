locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"

  values = yamlencode({
    clusterName = var.cluster_name
    createIngressClassResource = true

    serviceAccount = {
      name = var.service_account_name
      annotations = {
        "eks.${var.partition_dns}/role-arn": aws_iam_role.this.arn
      }
    }
  })
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values   = ["sts.${var.partition_dns}"]
      variable = "${var.oidc_issuer}:aud"
    }

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

resource "aws_security_group_rule" "this" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9443
  to_port                  = 9443
  description              = "Allow access from control plane to webhook port of AWS load balancer controller"
  security_group_id        = var.node_security_group_id
  source_security_group_id = var.cluster_security_group_id
}

resource "helm_release" "this" {
  chart      = "aws-load-balancer-controller"
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  values     = [local.values]
  version    = var.chart_version
}
