provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.auth.token
  }
}

locals {
  alb_controller_name  = "aws-load-balancer-controller"
  ebs_app_name         = "ebs-csi-controller-sa"
  efs_app_name         = "efs-csi-controller-sa"
  eks_addon_repository = lookup(local.eks_addon_repository_map, local.region_name)
}

resource "helm_release" "aws_alb_controller" {
  chart      = "aws-load-balancer-controller"
  name       = local.alb_controller_name
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  values     = [local.alb_controller_values]
  version    = "1.3.1"
}

resource "helm_release" "aws_ebs_csi_driver" {
  depends_on = [kubernetes_service_account.ebs_csi_driver]

  chart      = "aws-ebs-csi-driver"
  name       = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  values     = [local.ebs_driver_values]
  version    = "2.4.0"
}

resource "helm_release" "aws_efs_csi_driver" {
  depends_on = [kubernetes_service_account.efs_csi_driver]

  chart      = "aws-efs-csi-driver"
  name       = "aws-efs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  values     = [local.efs_driver_values]
  version    = "2.2.0"
}

data "aws_region" "this" {}

locals {
  alb_controller_values = <<EOT
clusterName: ${var.cluster_name}
image:
  repository: "${local.eks_addon_repository}/amazon/aws-load-balancer-controller"
serviceAccount:
  create: false
  name: ${kubernetes_service_account.alb_controller.metadata.0.name}
EOT

  ebs_driver_values = <<EOT
controller:
  extraVolumeTags: ${jsonencode(var.extra_tags)}
  serviceAccount:
    create: false
    name: ${kubernetes_service_account.ebs_csi_driver.metadata.0.name}
enableVolumeSnapshot: true
image:
  repository: "${local.eks_addon_repository}/eks/aws-ebs-csi-driver"
EOT

  efs_driver_values = <<EOT
controller:
  serviceAccount:
    create: false
    name: ${kubernetes_service_account.efs_csi_driver.metadata.0.name}
image:
  repository: "${local.eks_addon_repository}/eks/aws-efs-csi-driver"
EOT

  eks_addon_repository_map = {
    "af-south-1"     = "877085696533.dkr.ecr.af-south-1.amazonaws.com"
    "ap-east-1"      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com"
    "ap-northeast-1" = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com"
    "ap-northeast-2" = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"
    "ap-northeast-3" = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com"
    "ap-south-1"     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com"
    "ap-southeast-1" = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"
    "ap-southeast-2" = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"
    "ca-central-1"   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com"
    "cn-north-1"     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn"
    "cn-northwest-1" = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn"
    "eu-central-1"   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com"
    "eu-north-1"     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com"
    "eu-south-1"     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com"
    "eu-west-1"      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com"
    "eu-west-2"      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com"
    "eu-west-3"      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com"
    "me-south-1"     = "558608220178.dkr.ecr.me-south-1.amazonaws.com"
    "sa-east-1"      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com"
    "us-east-1"      = "602401143452.dkr.ecr.us-east-1.amazonaws.com"
    "us-east-2"      = "602401143452.dkr.ecr.us-east-2.amazonaws.com"
    "us-gov-east-1"  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com"
    "us-gov-west-1"  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com"
    "us-west-1"      = "602401143452.dkr.ecr.us-west-1.amazonaws.com"
    "us-west-2"      = "602401143452.dkr.ecr.us-west-2.amazonaws.com"
  }
}
