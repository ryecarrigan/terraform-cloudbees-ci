module "eks" {
  providers = { aws = "aws", kubernetes = "kubernetes" }
  source    = "./eks"

  bastion_count         = 1
  cluster_name          = var.cluster_name
  key_name              = var.key_name
  linux_nodes_desired   = 2
  node_instance_type    = "m5.xlarge"
  owner_key             = var.owner_key
  owner_value           = var.owner_value
  private_key_file      = var.private_key_file
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_ids     = module.vpc.public_subnet_ids
  ssh_cidr              = var.ssh_cidr
  vpc_id                = module.vpc.vpc_id
  windows_nodes_desired = 0
}

module "vpc" {
  providers = { aws = "aws" }
  source    = "./vpc"

  cluster_name = var.cluster_name
  owner_key    = var.owner_key
  owner_value  = var.owner_value
}

module "cloudbees_core" {
  source              = "./core"
  hibernation_enabled = true
  host_name           = var.host_name
}
