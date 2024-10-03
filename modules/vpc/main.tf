locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.zone_count)
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name                       = "${var.resource_prefix}_vpc"
  azs                        = local.availability_zones
  cidr                       = var.cidr_block
  enable_dns_hostnames       = true
  enable_nat_gateway         = true
  manage_default_network_acl = false
  private_subnet_tags        = var.private_subnet_tags
  private_subnets            = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 100 + i)]
  public_subnet_tags         = var.public_subnet_tags
  public_subnets             = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 200 + i)]
  single_nat_gateway         = true
  vpc_tags                   = var.vpc_tags
}
