provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.auth.token
}

resource "kubernetes_config_map" "iam_auth" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOT
- rolearn: ${module.eks_cluster.worker_iam_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOT
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name = var.nginx_namespace
  }
}

data "http" "wait_for_cluster" {
  ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  timeout        = 300
  url            = format("%s/healthz", data.aws_eks_cluster.cluster.endpoint)
}

data "kubernetes_service" "ingress_controller" {
  depends_on = [helm_release.ingress_nginx]

  metadata {
    namespace = var.nginx_namespace
    name      = "ingress-nginx-controller"
  }
}
