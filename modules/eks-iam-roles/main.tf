data "aws_iam_policy_document" "cluster" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.${var.partition_dns}"]
    }
  }
}

data "aws_iam_policy_document" "node" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${var.partition_dns}"]
    }
  }
}

locals {
  iam_role_policy_prefix = "arn:${var.partition_id}:iam::aws:policy"
}

resource "aws_iam_role" "cluster" {
  assume_role_policy    = data.aws_iam_policy_document.cluster.json
  force_detach_policies = true
  name_prefix           = "${var.cluster_name}-eks-cluster"

  tags = var.tags
}

resource "aws_iam_role" "node" {
  assume_role_policy    = data.aws_iam_policy_document.node.json
  force_detach_policies = true
  name_prefix           = "${var.cluster_name}-eks-node"

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset(["AmazonEKSClusterPolicy", "AmazonEKSVPCResourceController"])

  policy_arn = "${local.iam_role_policy_prefix}/${each.value}"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset(["AmazonEC2ContainerRegistryReadOnly", "AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy"])

  policy_arn = "${local.iam_role_policy_prefix}/${each.value}"
  role       = aws_iam_role.node.name
}
