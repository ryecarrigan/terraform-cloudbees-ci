provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

locals {
  ami_id             = data.aws_ssm_parameter.this.value
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.zone_count)
  cluster_name       = "${var.cluster_name}${local.workspace_suffix}"
  secret_properties  = fileexists(local.secret_props_file) ? file(local.secret_props_file) : ""
  secret_props_file  = "${path.module}/values/secrets.properties"
  workspace_suffix   = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_ssm_parameter" "this" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

module "vpc" {
  source = "../../modules/vpc"
  resource_prefix = var.cluster_name
}

module "acm_certificate" {
  source = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = var.subdomain
}

module "cjoc" {
  source = "../../modules/operations-center-ec2"

  acm_certificate_arn       = module.acm_certificate.certificate_arn
  ami_id                    = local.ami_id
  cluster_security_group_id = aws_security_group.cluster.id
  domain_name               = var.domain_name
  efs_file_system_id        = module.efs.file_system_id
  efs_iam_policy_arn        = module.efs.iam_policy_arn
  instance_type             = var.instance_type
  key_name                  = var.key_name
  private_subnets           = module.vpc.private_subnet_ids
  public_subnets            = module.vpc.public_subnet_ids
  resource_prefix           = var.cluster_name
  secret_properties         = local.secret_properties
  ssh_cidr_blocks           = var.ssh_cidr_blocks
  subdomain                 = var.subdomain
  vpc_id                    = module.vpc.id
}

module "bastion" {
  source = "../../modules/aws-bastion"

  ami_id                   = local.ami_id
  key_name                 = var.key_name
  resource_prefix          = var.cluster_name
  source_security_group_id = aws_security_group.cluster.id
  ssh_cidr_blocks          = var.ssh_cidr_blocks
  subnet_id                = coalesce(module.vpc.public_subnet_ids...)
  vpc_id                   = module.vpc.id
}

module "efs" {
  source = "../../modules/efs-file-system"

  vpc_id                    = module.vpc.id
  private_subnet_ids        = module.vpc.private_subnet_ids
  resource_prefix           = var.cluster_name
  source_security_group_id  = aws_security_group.cluster.id
}

resource "aws_security_group" "cluster" {
  description = "Security group of instances for cluster: ${var.cluster_name}"
  name_prefix = var.cluster_name
  vpc_id      = module.vpc.id

  lifecycle {
    create_before_destroy = true
  }
}
