module "cluster" {
  depends_on = [module.vpc]
  source     = "terraform-aws-modules/eks/aws"
  version    = "17.20.0"

  cluster_name     = var.cluster_name
  cluster_version  = var.eks_version
  manage_aws_auth  = false
  subnets          = module.vpc.private_subnets
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
      tags                     = [for k, v in var.extra_tags : {key = k, propagate_at_launch = true, value = v}]
      update_default_version   = true
    }
  ]
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url             = local.oidc_issuer_url

  tags = var.extra_tags
}

data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_id
}

data "aws_eks_cluster_auth" "auth" {
  name = module.cluster.cluster_id
}

data "http" "wait_for_cluster" {
  ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  timeout        = 300
  url            = "${data.aws_eks_cluster.cluster.endpoint}/healthz"
}

data "tls_certificate" "cluster" {
  url = local.oidc_issuer_url
}

locals {
  oidc_issuer       = trimprefix(local.oidc_issuer_url, "https://")
  oidc_issuer_url   = data.aws_eks_cluster.cluster.identity.0.oidc.0["issuer"]
  oidc_provider_arn = aws_iam_openid_connect_provider.oidc.arn
}
