resource "aws_security_group" "bastion" {
  name_prefix = "bastion"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = [
      var.ssh_cidr]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "tcp"
    to_port     = 65535
  }

  tags = {
    "${var.owner_key}" = var.owner_value
  }
}

resource "aws_security_group" "cluster_control_plane" {
  name   = "ClusterControlPlaneSecurityGroup"
  vpc_id = var.vpc_id

  tags = {
    "${var.owner_key}" = var.owner_value
  }
}

resource "aws_security_group" "node_security_group" {
  description            = "Security group for all nodes in the cluster"
  name_prefix            = "NodeSecurityGroup"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = map(
    local.cluster_name_tag, "owned",
    var.owner_key, var.owner_value
  )
}

resource "aws_security_group_rule" "bastion" {
  cidr_blocks       = [
    var.vpc_cidr]
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.node_security_group.id
  to_port           = 22
  type              = "ingress"
}

# Rules to add to the node security group.
resource "aws_security_group_rule" "node_security_group_ingress" {
  description       = "Allow node to communicate with each other"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.node_security_group.id
  self              = true
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "node_security_group_from_control_plane_ingress" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_security_group.id
  source_security_group_id = aws_security_group.cluster_control_plane.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_security_group_from_control_plane_on_443_ingress" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_security_group.id
  source_security_group_id = aws_security_group.cluster_control_plane.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_security_group_egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node_security_group.id
  to_port           = 0
  type              = "egress"
}

# Rules to add to the cluster control plane security group.
resource "aws_security_group_rule" "control_plane_egress_to_node_security_group" {
  description              = "Allow the cluster control plane to communicate with worker Kubelet and pods"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_control_plane.id
  source_security_group_id = aws_security_group.node_security_group.id
  to_port                  = 65535
  type                     = "egress"
}

resource "aws_security_group_rule" "cluster_control_plane_security_group" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_control_plane.id
  source_security_group_id = aws_security_group.node_security_group.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_control_plane_bastion" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_control_plane.id
  source_security_group_id = aws_security_group.bastion.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_control_plane_security_group-2" {
  description              = "Allow the cluster control plane to communicate with pods running extension API servers on port 443"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_control_plane.id
  source_security_group_id = aws_security_group.node_security_group.id
  to_port                  = 443
  type                     = "egress"
}
