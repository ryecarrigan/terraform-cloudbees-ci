locals {
  active_zones       = slice(local.availability_zones, 0, var.zone_count)
  availability_zones = data.aws_availability_zones.available.names
  private_subnets    = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 100 +  i)]
  public_subnets     = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 200 +  i)]
}

module "eks_vpc" {
  depends_on = [data.aws_availability_zones.available]
  source     = "terraform-aws-modules/vpc/aws"
  version    = "3.7.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = var.cidr_block
  azs                  = local.active_zones
  private_subnets      = local.private_subnets
  public_subnets       = local.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = merge({"kubernetes.io/cluster/${var.cluster_name}" = "shared"}, var.extra_tags)

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

data "aws_availability_zones" "available" {}
