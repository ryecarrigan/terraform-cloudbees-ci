resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.nat.id
  instance_type          = "t3.nano"
  key_name               = var.key_name
  subnet_id              = module.eks_vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = merge(
    {Name = "${var.cluster_name}-bastion"},
    var.extra_tags,
  )
}

data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}
