provider "aws" {}

locals {
  account_id  = data.aws_caller_identity.this.account_id
  ap_arn      = "arn:aws:elasticfilesystem:${local.region_name}:${local.account_id}:access-point/*"
  ec2_arn     = "arn:aws:ec2:${local.region_name}:${local.account_id}"
  issuer      = lookup(data.aws_eks_cluster.cluster.identity.0.oidc.0, "issuer")
  region_name = data.aws_region.this.name
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url             = local.issuer

  tags = var.extra_tags
}

resource "aws_iam_role" "ebs_csi_driver" {
  name_prefix = "${var.cluster_name}_ebs-csi-driver"

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
          "${trimprefix(local.issuer, "https://")}:sub": "system:serviceaccount:kube-system:${local.ebs_app_name}"
        }
      }
    }
  ]
}

EOF

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
          "${trimprefix(local.issuer, "https://")}:sub": "system:serviceaccount:kube-system:${local.efs_app_name}"
        }
      }
    }
  ]
}

EOF

  tags = var.extra_tags
}

resource "aws_iam_role_policy_attachment" "ebs_policy_attachment" {
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = aws_iam_policy.efs_csi_driver.arn
  role       = aws_iam_role.efs_csi_driver.name
}

resource "aws_iam_policy" "ebs_csi_driver" {
  name = "${var.cluster_name}_ebs-csi-driver"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:CreateTags"],
      "Resource": [
        "${local.ec2_arn}:volume",
        "${local.ec2_arn}:snapshot"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:DeleteTags"],
      "Resource": [
        "${local.ec2_arn}:volume/*",
        "${local.ec2_arn}:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:CreateVolume"],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:CreateVolume"],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:DeleteVolume"],
      "Resource": "${local.ec2_arn}:volume/*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:DeleteVolume"],
      "Resource": "${local.ec2_arn}:volume/*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:DeleteSnapshot"],
      "Resource": "${local.ec2_arn}:snapshot/*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:DeleteSnapshot"],
      "Resource": "${local.ec2_arn}:snapshot/*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOF

  tags = var.extra_tags
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
