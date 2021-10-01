provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.auth.token
  }
}

resource "helm_release" "aws_efs_csi_driver" {
  depends_on = [kubernetes_service_account.efs_csi_driver]

  chart      = "aws-efs-csi-driver"
  name       = "aws-efs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  version    = "2.2.0"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account.efs_csi_driver.metadata.0.name
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${data.aws_region.this.name}.amazonaws.com/eks/aws-efs-csi-driver"
  }
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
