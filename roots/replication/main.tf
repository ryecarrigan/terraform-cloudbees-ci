provider "aws" {
  region = var.secondary_region

  default_tags {
    tags = var.tags
  }
}


################################################################################
# Remote state and values
################################################################################
data "terraform_remote_state" "primary" {
  backend   = var.remote_state_backend
  config    = var.remote_state_config
  workspace = var.primary_workspace
}

data "terraform_remote_state" "secondary" {
  backend   = var.remote_state_backend
  config    = var.remote_state_config
  workspace = var.secondary_workspace
}

data "aws_s3_bucket" "primary" {
  bucket = local.primary_velero_bucket
}

data "aws_s3_bucket" "secondary" {
  bucket = local.secondary_velero_bucket
}

locals {
  primary_file_system_id   = data.terraform_remote_state.primary.outputs["efs_filesystem_id"]
  primary_velero_bucket    = data.terraform_remote_state.primary.outputs["velero_bucket"]
  secondary_file_system_id = data.terraform_remote_state.secondary.outputs["efs_filesystem_id"]
  secondary_velero_bucket  = data.terraform_remote_state.secondary.outputs["velero_bucket"]
}


################################################################################
# IAM role and policy for S3 replication
################################################################################
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [data.aws_s3_bucket.primary.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${data.aws_s3_bucket.primary.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${data.aws_s3_bucket.secondary.arn}/*"]
  }
}

resource "aws_iam_policy" "this" {
  name_prefix = substr(var.name_prefix, 0, 102)
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = substr(var.name_prefix, 0, 38)
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}


################################################################################
# Replication configuration
################################################################################
resource "aws_efs_replication_configuration" "this" {
  source_file_system_id = local.primary_file_system_id

  destination {
    file_system_id = local.secondary_file_system_id
    region         = var.secondary_region
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.this.arn
  bucket = data.aws_s3_bucket.primary.id

  rule {
    id     = var.replication_rule_id
    status = "Enabled"

    destination {
      bucket        = data.aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }
  }
}
