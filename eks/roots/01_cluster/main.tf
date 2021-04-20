terraform {
  backend "s3" {
    key = "cloudbees_sda/cluster/terraform.tfstate"
  }
}

provider "aws" {}

variable "cluster_name" {}
variable "eks_version" {}
variable "extra_tags" {
  default = {}
  type    = map(string)
}

variable "key_name" {
  default = ""
}

variable "ssh_cidr" {
  default = "0.0.0.0/32"
}

module "vpc" {
  source   = "../../modules/terraform-eks-vpc"

  cluster_name = var.cluster_name
  extra_tags   = var.extra_tags
}

module "eks_cluster" {
  source   = "../../modules/terraform-eks-cluster"

  bastion_count      = 1
  bastion_key_name   = var.key_name
  cluster_name       = var.cluster_name
  eks_version        = var.eks_version
  extra_tags         = var.extra_tags
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  ssh_cidr           = var.ssh_cidr
  vpc_id             = module.vpc.vpc_id
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
