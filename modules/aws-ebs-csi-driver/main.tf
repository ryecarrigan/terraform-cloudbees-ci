locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  volume_tags = {for k, v in var.volume_tags: "tagSpecification_${k}" => "${k}=${v}"}
}

resource "aws_iam_role" "this" {
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [{
      "Effect" = "Allow",
      "Principal" = {
        "Federated": var.oidc_provider_arn
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition" = {
        "StringLike" = {
          "${var.oidc_issuer}:sub" = "system:serviceaccount:kube-system:ebs-csi-*",
          "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  name_prefix = substr(local.name_prefix, 0, 38)
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.this.name
}

resource "aws_eks_addon" "this" {
  depends_on = [aws_iam_role_policy_attachment.this]

  addon_name               = "aws-ebs-csi-driver"
  cluster_name             = var.cluster_name
  service_account_role_arn = aws_iam_role.this.arn
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = merge({
    encrypted = "true"
    type      = "gp2"
  }, local.volume_tags)
}
