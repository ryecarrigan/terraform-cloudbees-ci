module "eks" {
  providers = { aws = "aws" }
  source    = "./eks"

  cluster_name       = var.cluster_name
  key_name           = var.key_name
  node_asg_desired   = 3
  owner_key          = var.owner_key
  owner_value        = var.owner_value
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  ssh_cidr           = var.ssh_cidr
  vpc_id             = module.vpc.vpc_id
}

module "vpc" {
  providers = { aws = "aws" }
  source    = "./vpc"

  cluster_name = var.cluster_name
  owner_key    = var.owner_key
  owner_value  = var.owner_value
}
