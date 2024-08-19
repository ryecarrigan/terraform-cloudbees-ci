locals {
  bucket_name = "${var.cluster_name}-velero"
  role_name   = "${var.cluster_name}-velero"
}

module "aws_s3_backups" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "4.1.2"

  bucket = local.bucket_name

  force_destroy = var.force_destroy_bucket

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
    status     = true
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

module "service_account_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_velero_policy  = true
  role_name_prefix      = local.role_name
  velero_s3_bucket_arns = [module.aws_s3_backups.s3_bucket_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_namespace.this]

  chart      = "velero"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://vmware-tanzu.github.io/helm-charts"
  values     = [local.values]
  version    = var.chart_version
}

locals {
  values = yamlencode({
    initContainers = [{
      name            = "velero-plugin-for-aws"
      image           = "velero/velero-plugin-for-aws:${var.plugin_image_tag}"
      imagePullPolicy = "IfNotPresent"
      volumeMounts = [{
        mountPath = "/target"
        name      = "plugins"
      }]
    }, {
      #https://github.com/cloudbees-oss/inject-metadata-velero-plugin
      name            = "inject-metadata-velero-plugin"
      image           = "ghcr.io/cloudbees-oss/inject-metadata-velero-plugin:main"
      imagePullPolicy = "Always"
      volumeMounts = [{
        mountPath = "/target"
        name      = "plugins"
      }]
    }]
    configuration = {
      backupStorageLocation = [{
        bucket   = module.aws_s3_backups.s3_bucket_id
        name     = "aws"
        provider = "aws"
        config = {
          region = module.aws_s3_backups.s3_bucket_region
        }
      }]
      volumeSnapshotLocation = [{
        name     = "aws"
        provider = "aws"
        config = {
          region = module.aws_s3_backups.s3_bucket_region
        }
      }]
    }

    serviceAccount = {
      server = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" : module.service_account_role.iam_role_arn
        }
      }
    }

    credentials = {
      useSecret = false
    }
  })
}
