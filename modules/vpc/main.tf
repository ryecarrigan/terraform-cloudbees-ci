locals {
  availability_zones = slice(local.az_names, 0, local.zone_count)
  az_count           = length(local.az_names)
  az_names           = data.aws_availability_zones.available.names
  zone_count         = var.zone_count <= local.az_count ? var.zone_count : local.az_count
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  # VPC flow logs
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  enable_flow_log                                 = true
  flow_log_cloudwatch_log_group_name_suffix       = var.resource_prefix
  flow_log_cloudwatch_log_group_retention_in_days = 7
  vpc_flow_log_iam_policy_name                    = "${var.resource_prefix}_flow-logs"
  vpc_flow_log_iam_role_name                      = "${var.resource_prefix}_flow-logs"

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
