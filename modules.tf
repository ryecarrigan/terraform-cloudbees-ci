module "eks" {
  providers = { aws = "aws", kubernetes = "kubernetes" }
  source    = "./eks"

  cluster_name       = var.cluster_name
  key_name           = var.key_name
  node_asg_desired   = 4
  node_asg_max_size  = 8
  node_instance_type = "m5.xlarge"
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

//module "mysql" {
//  providers = { helm = "helm" }
//  source    = "./mysql"
//
//  cluster_id     = module.eks.eks_cluster_id
//  mysql_database = var.mysql_database
//  mysql_password = var.mysql_password
//  mysql_user     = var.mysql_user
//}

//module "efs-provisioner" {
//  providers = { aws = "aws", kubernetes = "kubernetes" }
//  source    = "./efs-provisioner"
//
//  domain_name    = var.domain_name
//  file_system_id = module.eks.efs_id
//}
