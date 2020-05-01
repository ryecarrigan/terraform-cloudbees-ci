provider "aws" {
  version = "~> 2.58"
}

variable "bucket_name" {}

variable "extra_tags" {
  default = {}
  type    = "map"
}

resource "aws_s3_bucket" "state" {
  acl    = "private"
  bucket = var.bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = var.extra_tags
}
