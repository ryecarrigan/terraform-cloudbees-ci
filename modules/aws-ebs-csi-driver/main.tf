data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values   = ["sts.${var.dns_suffix}"]
      variable = "${var.oidc_issuer}:aud"
    }

    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:${var.service_account_name}"]
      variable = "${var.oidc_issuer}:sub"
    }

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.oidc_issuer}"]
    }
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = ["ec2:CreateTags"]
    effect  = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    condition {
      test     = "StringEquals"
      values   = ["CreateVolume", "CreateSnapshot"]
      variable = "ec2:CreateAction"
    }
  }

  statement {
    actions = ["ec2:DeleteTags"]
    effect  = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["true"]
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
    }
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "aws:RequestTag/CSIVolumeName"
    }
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["owned"]
      variable = "aws:RequestTag/kubernetes.io/cluster/*"
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["true"]
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "ec2:ResourceTag/CSIVolumeName"
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["owned"]
      variable = "ec2:ResourceTag/kubernetes.io/cluster/*"
    }
  }

  statement {
    actions   = ["ec2:DeleteSnapshot"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
    }
  }

  statement {
    actions   = ["ec2:DeleteSnapshot"]
    effect    = "Allow"
    resources = ["*"]

    condition {
      test     = "StringLike"
      values   = ["true"]
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
    }
  }
}

locals {
  values = yamlencode({
    controller = {
      extraVolumeTags = var.volume_tags

      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }

        name = var.service_account_name
      }
    }

    enableVolumeSnapshot = true

    image = {
      repository = "${var.eks_addon_repository}/eks/aws-ebs-csi-driver"
    }

    storageClasses = [{
      allowVolumeExpansion = true

      annotations = {
        "storageclass.kubernetes.io/is-default-class" = tostring(var.is_default_class)
      }

      name = var.storage_class_name

      parameters = {
        encrypted = "true"
        type      = "gp2"
      }
    }]
  })
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = "${var.cluster_name}_${var.release_name}"
}

resource "aws_iam_policy" "this" {
  name_prefix = "${var.cluster_name}_${var.release_name}"
  policy      = data.aws_iam_policy_document.policy.json
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
