module "eks_cluster" {
  depends_on = [module.eks_vpc]
  source     = "terraform-aws-modules/eks/aws"
  version    = "17.20.0"

  cluster_name     = var.cluster_name
  cluster_version  = var.eks_version
  manage_aws_auth  = false
  subnets          = module.eks_vpc.private_subnets
  vpc_id           = module.eks_vpc.vpc_id
  write_kubeconfig = false

  worker_groups_launch_template = [for subnet in module.eks_vpc.private_subnets :
    {
      name                     = subnet
      override_instance_types  = var.instance_types
      spot_instance_pools      = 1
      asg_max_size             = 4
      asg_desired_capacity     = 1
      instance_refresh_enabled = true
      key_name                 = var.key_name
      subnets                  = [subnet]
      tags                     = [for k, v in var.extra_tags : {key = k, propagate_at_launch = true, value = v}]
      update_default_version   = true
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "auth" {
  name = module.eks_cluster.cluster_id
}
