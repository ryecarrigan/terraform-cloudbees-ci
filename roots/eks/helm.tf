provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.auth.token
  }
}

locals {
  ebs_app_name = "ebs-csi-controller-sa"
  efs_app_name = "efs-csi-controller-sa"

  ebs_driver_values = <<EOT
controller:
  extraVolumeTags: ${jsonencode(var.extra_tags)}
  serviceAccount:
    create: false
    name: ${local.ebs_app_name}
enableVolumeSnapshot: true
EOT

  efs_driver_Values = <<EOT
controller:
  serviceAccount:
    create: false
    name: ${local.efs_app_name}

image:
  repository: "602401143452.dkr.ecr.${local.region_name}.amazonaws.com/eks/aws-efs-csi-driver"
EOT
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
  values     = [local.efs_driver_Values]
  version    = "2.2.0"
}

resource "helm_release" "ingress_nginx" {
  depends_on = [kubernetes_namespace.ingress_nginx]

  chart      = "ingress-nginx"
  name       = "ingress-nginx"
  namespace  = var.nginx_namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  values     = [data.template_file.ingress_nginx.rendered]
  version    = "4.0.3"
}

data "aws_region" "this" {}

data "template_file" "ingress_nginx" {
  template = file("${path.module}/values/ingress-nginx.yaml.tpl")
  vars = {
    acm_certificate_arn = aws_acm_certificate.certificate.id
  }
}
