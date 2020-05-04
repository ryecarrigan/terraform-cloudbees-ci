provider "aws" {
  version = "~> 2.58"
}

provider "template" {
  version = "~> 2.1"
}

terraform {
  backend "s3" {
    key = "terraform_cbci/cluster_setup/terraform.tfstate"
  }
}

variable "cluster_name" {}
variable "extra_tags" {
  default = {}
  type    = "map"
}

variable "instance_type" {
  default = "m5a.large"
}

variable "key_name" {
  default = ""
}

variable "ssh_cidr" {
  default = "0.0.0.0/32"
}

module "vpc" {
  providers = { aws = "aws" }
  source    = "git@github.com:ryecarrigan/terraform-eks-vpc.git?ref=v1.1.1"

  cluster_name = var.cluster_name
  extra_tags   = var.extra_tags
}

module "eks_cluster" {
  providers = { aws = "aws" }
  source    = "git@github.com:ryecarrigan/terraform-eks-cluster.git?ref=v1.2.0"

  bastion_count      = 0
  bastion_key_name   = var.key_name
  cluster_name       = var.cluster_name
  eks_version        = local.eks_version
  extra_tags         = var.extra_tags
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  ssh_cidr           = var.ssh_cidr
  vpc_id             = module.vpc.vpc_id
}

module "eks_linux" {
  providers = { aws = "aws" }
  source    = "git@github.com:ryecarrigan/terraform-eks-asg.git?ref=v2.1.0"

  autoscaler_enabled   = true
  cluster_name         = var.cluster_name
  desired_nodes_per_az = 1
  extra_tags           = var.extra_tags
  image_id             = data.aws_ami.linux_ami.image_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  minimum_nodes_per_az = 1
  node_name_prefix     = "${var.cluster_name}-linux"
  security_group_ids   = [module.eks_cluster.node_security_group_id]
  subnet_ids           = module.vpc.private_subnet_ids
  user_data            = data.template_file.linux_user_data.rendered
}

# Windows nodes untested since latest update; not guaranteed without issues.
module "eks_windows" {
  providers = { aws = "aws" }
  source    = "git@github.com:ryecarrigan/terraform-eks-asg.git?ref=v2.1.0"

  autoscaler_enabled   = false
  cluster_name         = var.cluster_name
  desired_nodes_per_az = 0
  extra_tags           = var.extra_tags
  image_id             = data.aws_ssm_parameter.windows_ami.value
  instance_type        = var.instance_type
  minimum_nodes_per_az = 0
  node_name_prefix     = "${var.cluster_name}-windows"
  security_group_ids   = [module.eks_cluster.node_security_group_id]
  subnet_ids           = module.vpc.private_subnet_ids
  user_data            = data.template_file.windows_user_data.rendered
}

data "aws_ami" "linux_ami" {
  most_recent = true
  owners      = ["602401143452"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.eks_version}-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-${local.eks_version}/image_id"
}

data "template_file" "linux_user_data" {
  template = file("linux_user_data.tpl")
  vars = {
    bootstrap_arguments = ""
    cluster_name        = var.cluster_name
  }
}

data "template_file" "windows_user_data" {
  template = file("windows_user_data.tpl")
  vars = {
    cluster_name = var.cluster_name
  }
}

output "linux_node_role_arn" {
  value = module.eks_linux.node_role_arn
}

output "node_security_group_id" {
  value = module.eks_cluster.node_security_group_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "windows_node_role_arn" {
  value = module.eks_windows.node_role_arn
}

locals {
  eks_version = "1.15"
}
