provider "aws" {}

locals {
  ap_arn = "arn:aws:elasticfilesystem:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:access-point/*"
  issuer = lookup(data.aws_eks_cluster.cluster.identity.0.oidc.0, "issuer")
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = local.issuer

  tags = var.extra_tags
}

resource "aws_iam_role" "efs_csi_driver" {
  name_prefix = "${var.cluster_name}_efs-csi-driver"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.oidc.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${trimprefix(local.issuer, "https://")}:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }
  ]
}

EOF

  tags = var.extra_tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = aws_iam_policy.efs_csi_driver.arn
  role       = aws_iam_role.efs_csi_driver.name
}

resource "aws_iam_policy" "efs_csi_driver" {
  name = "${var.cluster_name}_efs-csi-driver"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["elasticfilesystem:DescribeAccessPoints"],
      "Resource": "${local.ap_arn}"
    },
    {
      "Effect": "Allow",
      "Action": ["elasticfilesystem:DescribeFileSystems"],
      "Resource": "${aws_efs_file_system.efs_file_system.arn}"
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
      "Resource": "${local.ap_arn}",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOF

  tags = var.extra_tags
}

data "aws_caller_identity" "this" {}

data "tls_certificate" "cluster" {
  url = local.issuer
}
