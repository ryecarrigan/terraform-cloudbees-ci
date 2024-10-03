locals {
  protection = (var.replication_protection) ? "ENABLED" : "DISABLED"
}

resource "aws_efs_file_system" "this" {
  encrypted = var.encrypt_file_system
  tags = {
    Name = var.resource_prefix
  }

  protection {
    replication_overwrite = local.protection
  }

  lifecycle {
    ignore_changes = [protection]
  }
}

resource "aws_efs_mount_target" "this" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.this.id]
  subnet_id       = var.private_subnet_ids[count.index]
}

resource "aws_iam_policy" "this" {
  name_prefix = "${var.resource_prefix}_EFS"
  policy      = templatefile("${path.module}/policy.json.tftpl", {file_system_arn: aws_efs_file_system.this.arn})
}

resource "aws_security_group" "this" {
  description = "[${var.resource_prefix}] Security group for EFS mount targets"
  name_prefix = var.resource_prefix
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress" {
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = var.source_security_group_id
  source_security_group_id = aws_security_group.this.id
  to_port                  = 2049
  type                     = "egress"
}

resource "aws_security_group_rule" "ingress" {
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group_id
  to_port                  = 2049
  type                     = "ingress"
}
