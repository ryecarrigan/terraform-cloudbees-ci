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

locals {
  name_prefix = "${var.cluster_name}_${var.release_name}"

  values = yamlencode({
    controller = {
      extraVolumeTags = var.volume_tags

      serviceAccount = {
        annotations = {
          "eks.${var.partition_dns}/role-arn" = aws_iam_role.this.arn
        }

        name = var.service_account_name
      }
    }

    enableVolumeSnapshot = true

    storageClasses = [{
      allowVolumeExpansion = true
      name = var.storage_class_name

      parameters = {
        encrypted = "true"
        type      = "gp2"
      }
    }]
  })
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

resource "helm_release" "this" {
  chart      = "aws-ebs-csi-driver"
  name       = var.release_name
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  values     = [local.values]
  version    = var.release_version
}
