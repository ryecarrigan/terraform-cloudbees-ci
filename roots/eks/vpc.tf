module "vpc" {
  depends_on = [data.aws_availability_zones.available]
  source     = "terraform-aws-modules/vpc/aws"
  version    = "3.7.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = var.cidr_block
  azs                  = slice(data.aws_availability_zones.available.names, 0, var.zone_count)
  private_subnets      = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 100 +  i)]
  public_subnets       = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 200 +  i)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = merge({"kubernetes.io/cluster/${var.cluster_name}" = "shared"}, var.extra_tags)

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "bastion" {
  depends_on = [module.vpc]
  source     = "../../modules/aws-bastion"

  resource_prefix          = var.cluster_name
  source_security_group_id = module.cluster.worker_security_group_id
  ssh_cidr_blocks          = [var.ssh_cidr]
  subnet_id                = module.vpc.public_subnets.0
  vpc_id                   = module.vpc.vpc_id
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.certificate_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  depends_on = [aws_acm_certificate.certificate]
  for_each   = {for option in aws_acm_certificate.certificate.domain_validation_options : option.domain_name => option}

  name     = each.value["resource_record_name"]
  records  = [each.value["resource_record_value"]]
  ttl      = 60
  type     = each.value["resource_record_type"]
  zone_id  = data.aws_route53_zone.domain_name.id
}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "domain_name" {
  name = length(var.zone_name) > 0 ? var.zone_name : var.certificate_domain_name
}
