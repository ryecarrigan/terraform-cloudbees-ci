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
}

resource "aws_launch_configuration" "node_launch_config" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.id
  image_id                    = data.aws_ami.eks_optimized.id
  instance_type               = var.node_instance_type
  key_name                    = var.key_name
  name_prefix                 = local.node_group_name
  security_groups             = [aws_security_group.node_security_group.id]
  user_data                   = local.node_user_data

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node_group" {
  depends_on           = [aws_eks_cluster.cluster]
  desired_capacity     = var.node_asg_desired
  launch_configuration = aws_launch_configuration.node_launch_config.id
  max_size             = var.node_asg_max_size
  min_size             = var.node_asg_min_size
  name_prefix          = local.node_group_name
  vpc_zone_identifier  = var.private_subnet_ids

  tags = [
    {
      key                 = "Name"
      propagate_at_launch = true
      value               = "${var.cluster_name}-${var.node_group_name}"
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

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.nat.id
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.id
  instance_type          = "t3.nano"
  key_name               = var.key_name
  subnet_id              = var.public_subnet_ids[0]
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
