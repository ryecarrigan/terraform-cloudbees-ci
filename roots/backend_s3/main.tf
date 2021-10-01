variable "bucket_name" {}

variable "extra_tags" {
  default = null
  type    = map(string)
}

resource "aws_s3_bucket" "this" {
  acl           = "private"
  bucket        = var.bucket_name
  force_destroy = false

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
