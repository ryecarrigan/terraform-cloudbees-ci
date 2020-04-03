# Use the AWS-provisioned IAM role for auto-scaling
data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForAutoScaling"
}

# Reference the AWS-provided AMI ID
data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-${var.eks_version}/image_id"
}

resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.eks_service_role.arn
  version                   = var.eks_version

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster_control_plane.id]
    subnet_ids              = var.private_subnet_ids
  }

  provisioner "local-exec" {
    command = "aws eks --region ${local.region_name} update-kubeconfig --name ${var.cluster_name}"
  }
}

resource "aws_instance" "bastion" {
  count      = var.bastion_count
  depends_on = [aws_eks_cluster.cluster]

  ami                    = data.aws_ami.nat.id
  iam_instance_profile   = aws_iam_instance_profile.linux_node.id
  instance_type          = "t3.nano"
  key_name               = var.key_name
  subnet_id              = var.public_subnet_ids[count.index]
  user_data              = local.bastion_user_data
  vpc_security_group_ids = [
    aws_security_group.bastion.id,
    aws_security_group.cluster_control_plane.id,
  ]

  tags = {
    Name               = "${var.cluster_name}-bastion"
    "${var.owner_key}" = var.owner_value
  }
}

resource "aws_launch_configuration" "linux" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.linux_node.id
  image_id                    = data.aws_ami.eks_optimized.id
  instance_type               = var.node_instance_type
  key_name                    = var.key_name
  name_prefix                 = local.linux_prefix
  security_groups             = [aws_security_group.node_security_group.id]
  user_data                   = local.node_user_data

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "windows" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.windows_node.id
  image_id                    = data.aws_ssm_parameter.windows_ami.value
  instance_type               = var.node_instance_type
  key_name                    = var.key_name
  name_prefix                 = local.windows_prefix
  security_groups             = [aws_security_group.node_security_group.id]
  user_data                   = local.windows_user_data

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }
}

resource "aws_autoscaling_group" "linux" {
  depends_on               = [aws_eks_cluster.cluster]
  desired_capacity         = var.linux_nodes_desired
  launch_configuration     = aws_launch_configuration.linux.id
  max_size                 = var.linux_nodes_max
  min_size                 = var.linux_nodes_min
  name_prefix              = local.linux_prefix
  service_linked_role_arn  = data.aws_iam_role.autoscaling.arn
  vpc_zone_identifier      = var.private_subnet_ids

  tags = [
    {
      key                 = "Name"
      propagate_at_launch = true
      value               = local.linux_prefix
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      propagate_at_launch = true
      value               = "owned"
    },
    {
      key                 = var.owner_key
      propagate_at_launch = true
      value               = var.owner_value
    }
  ]
}

resource "aws_autoscaling_group" "windows" {
  desired_capacity        = var.windows_nodes_desired
  launch_configuration    = aws_launch_configuration.windows.id
  max_size                = var.windows_nodes_max
  min_size                = var.windows_nodes_min
  name_prefix             = local.windows_prefix
  service_linked_role_arn = data.aws_iam_role.autoscaling.arn
  vpc_zone_identifier     = var.private_subnet_ids

  tags = [
    {
      key                 = "Name"
      propagate_at_launch = true
      value               = local.windows_prefix
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      propagate_at_launch = true
      value               = "owned"
    },
    {
      key                 = var.owner_key
      propagate_at_launch = true
      value               = var.owner_value
    }
  ]
}
