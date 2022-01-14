module "cluster" {
  depends_on = [module.vpc]
  source     = "terraform-aws-modules/eks/aws"
  version    = "17.20.0"

  cluster_name     = var.cluster_name
  cluster_version  = var.eks_version
  enable_irsa      = true
  manage_aws_auth  = true
  subnets          = module.vpc.private_subnets
  tags             = var.extra_tags
  vpc_id           = module.vpc.vpc_id
  write_kubeconfig = false

  worker_groups_launch_template = [for subnet in module.vpc.private_subnets :
    {
      name                     = subnet
      override_instance_types  = var.instance_types
      spot_instance_pools      = 1
      asg_max_size             = 4
      asg_desired_capacity     = 1
      instance_refresh_enabled = true
      key_name                 = var.key_name
      subnets                  = [subnet]
      tags                     = [for k, v in local.worker_group_tags : {key = k, propagate_at_launch = true, value = v}]
      update_default_version   = true
    }
  ]
}

data "aws_eks_cluster_auth" "auth" {
  name = module.cluster.cluster_id
}

data "http" "wait_for_cluster" {
  ca_certificate = local.cluster_ca_certificate
  timeout        = 300
  url            = "${local.cluster_endpoint}/healthz"
}

locals {
  cluster_endpoint       = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
  oidc_issuer            = trimprefix(module.cluster.cluster_oidc_issuer_url, "https://")
  oidc_provider_arn      = module.cluster.oidc_provider_arn
  worker_group_tags      = {
    "k8s.io/cluster-autoscaler/enabled"             = true
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }
}
