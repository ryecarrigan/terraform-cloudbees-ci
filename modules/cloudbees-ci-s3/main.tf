locals {
  name = "${var.bucket_prefix}-${var.bucket_suffix}"
}

module "aws_s3_backups" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "4.1.2"

  bucket = local.name

  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  acl = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    status     = false
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_policy" "this" {
  name   = local.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketLocation",
            "s3:ListBucket"
          ],
          "Resource": "arn:aws:s3:::${module.aws_s3_backups.s3_bucket_id}"
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject"
          ],
          "Resource": "arn:aws:s3:::${module.aws_s3_backups.s3_bucket_id}/*"
      }
  ]
}
EOF
}

data "aws_iam_role" "this" {
  for_each = var.iam_roles
  name     = each.value
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = data.aws_iam_role.this
  policy_arn = aws_iam_policy.this.arn
  role       = each.value.name
}
