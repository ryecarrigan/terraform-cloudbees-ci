resource "helm_release" "this" {
  chart      = "external-dns"
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://charts.bitnami.com/bitnami"
  values     = [local.helm_values]
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

resource "aws_iam_policy" "this" {
  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "${data.aws_route53_zone.this.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOT

  tags = var.extra_tags
}

resource "aws_iam_role" "this" {
  name_prefix = "${var.cluster_name}_external-dns"

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

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

data "aws_route53_zone" "this" {
  zone_id = var.route53_zone_id
}

locals {
  helm_values = <<EOT
provider: aws
serviceAccount:
  create: false
  name: ${kubernetes_service_account.this.metadata.0.name}
zoneIdFilters: ["${data.aws_route53_zone.this.id}"]
EOT
}
