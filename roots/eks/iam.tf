provider "aws" {}

locals {
  issuer = lookup(data.aws_eks_cluster.cluster.identity.0.oidc.0, "issuer")
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazon.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = local.issuer

  tags = var.extra_tags
}

data "tls_certificate" "cluster" {
  url = local.issuer
}
