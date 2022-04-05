data "aws_ssm_parameter" "this" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.this.value
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]

  tags = {
    Name = "${var.resource_prefix}-${var.resource_suffix}"
  }
}

resource "aws_security_group" "this" {
  description = "Security group for the bastion instance"
  name_prefix = "${var.resource_prefix}-${var.resource_suffix}"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  to_port           = 65535
  type              = "egress"
}

resource "aws_security_group_rule" "ingress" {
  cidr_blocks       = var.ssh_cidr_blocks
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "source" {
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group_id
  to_port                  = 22
  type                     = "ingress"
}
