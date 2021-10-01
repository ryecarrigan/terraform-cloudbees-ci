provider "aws" {}

locals {
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
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = data.aws_iam_policy.efs_csi_driver.arn
  role       = aws_iam_role.efs_csi_driver.name
}

data "aws_iam_policy" "efs_csi_driver" {
  name = "AmazonEKS_EFS_CSI_Driver_Policy"
}

data "tls_certificate" "cluster" {
  url = local.issuer
}
