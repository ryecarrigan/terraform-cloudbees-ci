module "velero_eks_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "velero-${terraform.workspace}"
  attach_velero_policy  = true
  velero_s3_bucket_arns = [var.s3_bucket_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.k8s_cluster_oidc_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account}"]
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
  replace    = true
}

locals {
  values = yamlencode({
    initContainers = [{
      name            = "velero-plugin-for-aws"
      image           = "velero/velero-plugin-for-aws:v1.3.0"
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
      provider = "aws"
      backupStorageLocation = {
        bucket = var.bucket_name
        config = {
          region = var.region_name
        }
      }
      volumeSnapshotLocation = {
        config = {
          region = var.region_name
        }
      }
    }
    serviceAccount = {
      server = {
        create = true
        name   = "${var.service_account}"
        annotations = {
          "eks.amazonaws.com/role-arn" : "${module.velero_eks_role.iam_role_arn}"
        }
      }
    }
    credentials = {
      useSecret = false
    }

  })
}
