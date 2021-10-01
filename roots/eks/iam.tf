#resource "aws_iam_instance_profile" "node" {
#  name_prefix = var.cluster_name
#  role        = aws_iam_role.node.id
#}
#
#resource "aws_iam_role" "node" {
#  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
#  name               = var.cluster_name
#
#  tags = var.extra_tags
#}
#
#resource "aws_iam_policy" "eks_autoscaling" {
#  description = "EKS worker node autoscaling policy for cluster ${var.cluster_name}"
#  name_prefix = "${var.cluster_name}-autoscaling"
#  policy      = data.aws_iam_policy_document.autoscaling.json
#}
#
#resource "aws_iam_policy" "eks" {
#  description = "Collects policies from required managed policy documents"
#  name_prefix = "${var.cluster_name}-eks"
#  policy      = data.aws_iam_policy_document.eks.json
#}
#
#resource "aws_iam_role_policy_attachment" "eks" {
#  policy_arn = aws_iam_policy.eks.arn
#  role       = aws_iam_role.node.id
#}
#
#resource "aws_iam_role_policy_attachment" "eks_autoscaling" {
#  policy_arn = aws_iam_policy.eks_autoscaling.arn
#  role       = aws_iam_role.node.id
#}
#
#resource "aws_iam_policy" "alb_controller" {
#  name   = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
#  policy = file("${path.module}/iam-policy-alb-controller.json")
#}
#
#resource "aws_iam_role_policy_attachment" "policy_attachment" {
#  policy_arn = aws_iam_policy.alb_controller.arn
#  role       = aws_iam_role.node.id
#}
#
#data "aws_iam_policy_document" "assume_role_ec2" {
#  statement {
#    actions = ["sts:AssumeRole"]
#    effect  = "Allow"
#
#    principals {
#      identifiers = ["ec2.amazonaws.com"]
#      type        = "Service"
#    }
#  }
#}
#
#data "aws_iam_policy_document" "autoscaling" {
#  statement {
#    sid    = "eksWorkerAutoscalingAll"
#    effect = "Allow"
#
#    actions = [
#      "autoscaling:DescribeAutoScalingGroups",
#      "autoscaling:DescribeAutoScalingInstances",
#      "autoscaling:DescribeLaunchConfigurations",
#      "autoscaling:DescribeTags",
#      "ec2:DescribeLaunchTemplateVersions",
#    ]
#
#    resources = ["*"]
#  }
#
#  statement {
#    actions = [
#      "autoscaling:SetDesiredCapacity",
#      "autoscaling:TerminateInstanceInAutoScalingGroup",
#      "autoscaling:UpdateAutoScalingGroup",
#    ]
#
#    effect    = "Allow"
#    resources = ["*"]
#    sid       = "eksWorkerAutoscalingOwn"
#
#    condition {
#      test     = "StringEquals"
#      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
#      values   = ["owned"]
#    }
#
#    condition {
#      test     = "StringEquals"
#      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
#      values   = ["true"]
#    }
#  }
#}
#
#data "aws_iam_policy_document" "eks" {
#  statement {
#    actions = [
#      "ecr:GetAuthorizationToken",
#      "ecr:BatchCheckLayerAvailability",
#      "ecr:GetDownloadUrlForLayer",
#      "ecr:GetRepositoryPolicy",
#      "ecr:DescribeRepositories",
#      "ecr:ListImages",
#      "ecr:DescribeImages",
#      "ecr:BatchGetImage",
#      "ecr:GetLifecyclePolicy",
#      "ecr:GetLifecyclePolicyPreview",
#      "ecr:ListTagsForResource",
#      "ecr:DescribeImageScanFindings",
#    ]
#
#    effect    = "Allow"
#    sid       = "AmazonEC2ContainerRegistryReadOnly"
#    resources = ["*"]
#  }
#
#  statement {
#    actions = [
#      "ec2:AssignPrivateIpAddresses",
#      "ec2:AttachNetworkInterface",
#      "ec2:CreateNetworkInterface",
#      "ec2:DeleteNetworkInterface",
#      "ec2:DescribeInstances",
#      "ec2:DescribeTags",
#      "ec2:DescribeNetworkInterfaces",
#      "ec2:DescribeInstanceTypes",
#      "ec2:DetachNetworkInterface",
#      "ec2:ModifyNetworkInterfaceAttribute",
#      "ec2:UnassignPrivateIpAddresses",
#    ]
#
#    effect    = "Allow"
#    resources = ["*"]
#    sid       = "AmazonEKSCNIPolicy1"
#  }
#
#  statement {
#    actions   = ["ec2:CreateTags"]
#    effect    = "Allow"
#    resources = ["arn:aws:ec2:*:*:network-interface/*"]
#    sid       = "AmazonEKSCNIPolicy2"
#  }
#
#  statement {
#    actions = [
#      "ec2:DescribeInstances",
#      "ec2:DescribeRouteTables",
#      "ec2:DescribeSecurityGroups",
#      "ec2:DescribeSubnets",
#      "ec2:DescribeVolumes",
#      "ec2:DescribeVolumesModifications",
#      "ec2:DescribeVpcs",
#      "eks:DescribeCluster",
#    ]
#
#    effect    = "Allow"
#    resources = ["*"]
#    sid       = "AmazonEKSWorkerNodePolicy"
#  }
#}
