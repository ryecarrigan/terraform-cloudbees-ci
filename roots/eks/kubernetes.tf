provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.auth.token
}

locals {
  ebs_sc_name = "ebs"
  efs_sc_name = "efs"
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

resource "kubernetes_storage_class" "aws_ebs_csi_driver" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name = local.ebs_sc_name
  }

  parameters = {
    encrypted = true
    type      = "gp2"
  }

  storage_provisioner = "ebs.csi.aws.com"
}

resource "kubernetes_storage_class" "aws_efs_csi_driver" {
  depends_on = [aws_efs_mount_target.efs_mount_target, data.http.wait_for_cluster]

  metadata {
    name = local.efs_sc_name
  }

  parameters = {
    directoryPerms   = "700"
    fileSystemId     = aws_efs_file_system.efs_file_system.id
    provisioningMode = "efs-ap"
  }

  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_service_account" "alb_controller" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name      = local.alb_controller_name
    namespace = "kube-system"

    annotations = {"eks.amazonaws.com/role-arn": aws_iam_role.alb_controller.arn}

    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = local.alb_controller_name
    }
  }
}

resource "kubernetes_service_account" "ebs_csi_driver" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name      = local.ebs_app_name
    namespace = "kube-system"

    annotations = {"eks.amazonaws.com/role-arn": aws_iam_role.ebs_csi_driver.arn}
    labels      = {"app.kubernetes.io/name": local.ebs_app_name}
  }
}

resource "kubernetes_service_account" "efs_csi_driver" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name      = local.efs_app_name
    namespace = "kube-system"

    annotations = {"eks.amazonaws.com/role-arn": aws_iam_role.efs_csi_driver.arn}
    labels      = {"app.kubernetes.io/name": local.efs_app_name}
  }
}

data "http" "wait_for_cluster" {
  ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  timeout        = 300
  url            = format("%s/healthz", data.aws_eks_cluster.cluster.endpoint)
}
