data "aws_route53_zone" "domain_name" {
  name = var.domain_name
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  iam_instance_profile   = aws_iam_instance_profile.this.name
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = coalesce(var.private_subnets...)
  user_data              = templatefile("${path.module}/user_data.sh.tftpl", {access_point_id: aws_efs_access_point.this.id, file_system_id: var.efs_file_system_id})
  vpc_security_group_ids = [aws_security_group.this.id, var.cluster_security_group_id]

  tags = {
    Name = "${var.resource_prefix}-${var.resource_suffix}"
  }
}

resource "aws_iam_role" "this" {
  name = "${var.resource_prefix}_cjoc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
    }]
  })
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = var.resource_prefix
  role        = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = var.efs_iam_policy_arn
  role       = aws_iam_role.this.name
}

resource "aws_efs_access_point" "this" {
  file_system_id = var.efs_file_system_id

  root_directory {
    path = "/cjoc"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "700"
    }
  }
}

resource "aws_route53_record" "this" {
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "CNAME"
  records = [aws_lb.this.dns_name]
  ttl     = 300
  zone_id = data.aws_route53_zone.domain_name.id
}

resource "aws_lb" "this" {
  name               = "${var.resource_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.resource_prefix}-lb"
  port     = 8888
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.this.id
  port             = 8888
}

resource "aws_security_group" "this" {
  description = "Security group for the CJOC instance"
  name_prefix = "${var.resource_prefix}-${var.resource_suffix}-ec2"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb" {
  description = "Security group for the CJOC ALB"
  name_prefix = "${var.resource_prefix}-${var.resource_suffix}-alb"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ec2_egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  to_port           = 65535
  type              = "egress"
}

resource "aws_security_group_rule" "alb_egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 65535
  type              = "egress"
}

resource "aws_security_group_rule" "https" {
  cidr_blocks       = var.ssh_cidr_blocks
  description       = "HTTPS ingress from provided CIDR"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "http" {
  description              = "HTTP ingress from load balancer"
  from_port                = 8888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = aws_security_group.alb.id
  to_port                  = 8888
  type                     = "ingress"
}
