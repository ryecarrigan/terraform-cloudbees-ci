resource "aws_iam_role" "eks_service_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_eks.json
  name               = "eksServiceRole-${var.cluster_name}"

  tags = {
    "${var.owner_key}" = var.owner_value
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_service_role.id
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_service_role.id
}

data "aws_iam_policy_document" "assume_role_eks" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["eks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_policy_attachment" "eks_cni" {
  name       = "${var.cluster_name}-eks-cni"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  roles      = [aws_iam_role.linux_node.id, aws_iam_role.windows_node.id]
}

resource "aws_iam_policy_attachment" "eks_worker_node" {
  name       = "${var.cluster_name}-eks-cluster"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  roles      = [aws_iam_role.linux_node.id, aws_iam_role.windows_node.id]
}

resource "aws_iam_policy_attachment" "ecr_read_only" {
  name       = "${var.cluster_name}-eks-service"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  roles      = [aws_iam_role.linux_node.id, aws_iam_role.windows_node.id]
}

resource "aws_iam_instance_profile" "linux_node" {
  name_prefix = local.linux_prefix
  role        = aws_iam_role.linux_node.id
}

resource "aws_iam_role" "linux_node" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
  name               = local.linux_prefix

  tags = {
    "${var.owner_key}" = var.owner_value
  }
}

resource "aws_iam_role" "windows_node" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
  name               = local.windows_prefix

  tags = {
    "${var.owner_key}" = var.owner_value
  }
}

resource "aws_iam_instance_profile" "windows_node" {
  name_prefix = local.windows_prefix
  role        = aws_iam_role.windows_node.id
}

resource "kubernetes_config_map" "iam-auth" {
  depends_on = [aws_eks_cluster.cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: ${aws_iam_role.linux_node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${aws_iam_role.windows_node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
    - eks:kube-proxy-windows
    EOF
  }
}
