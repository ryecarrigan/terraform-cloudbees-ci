provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.auth.token
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

data "template_file" "ingress_nginx" {
  template = file("${path.module}/values/ingress-nginx.yaml.tpl")
  vars = {
    acm_certificate_arn = aws_acm_certificate.certificate.id
  }
}
