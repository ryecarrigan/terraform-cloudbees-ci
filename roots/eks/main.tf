provider "aws" {
  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_auth_token
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_auth_token
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_name
}

data "aws_region" "current" {}

data "aws_route53_zone" "domain" {
  name = var.domain_name
}

locals {
  availability_zones     = slice(data.aws_availability_zones.available.names, 0, var.zone_count)
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_region             = data.aws_region.current.name
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  cluster_name           = "${var.cluster_name}${local.workspace_suffix}"
  ingress_class_name     = "alb"
  kubeconfig_file        = "${path.cwd}/${var.kubeconfig_file}"
  oidc_issuer            = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
  oidc_provider_arn      = module.eks.oidc_provider_arn
  this                   = toset(["this"])
  workspace_suffix       = terraform.workspace == "default" ? "" : "-${terraform.workspace}"

  agents_role_name      = substr("${local.cluster_name}-agents", 0, 38)
  controllers_role_name = substr("${local.cluster_name}-controllers", 0, 38)

  vpc_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  alb_annotations = {
    "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
    "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
    "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
    "alb.ingress.kubernetes.io/tags"                 = join(",", [for k, v in var.tags : "${k}=${v}"])
    "alb.ingress.kubernetes.io/target-type"          = "ip"
  }

  alb_redirect_path = {
    pathType = "ImplementationSpecific"
    backend = {
      service = {
        name = "ssl-redirect"
        port = {
          name = "use-annotation"
        }
      }
    }
  }

  cluster_autoscaler_tag = var.cluster_autoscaler_tag != "" ? var.cluster_autoscaler_tag : "v${var.kubernetes_version}.0"
}


################################################################################
# Amazon VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                 = "${local.cluster_name}-vpc"
  cidr                 = var.cidr_block
  azs                  = local.availability_zones
  manage_default_network_acl = false
  private_subnets      = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 100 + i)]
  public_subnets       = [for i in range(0, var.zone_count) : cidrsubnet(var.cidr_block, 8, 200 + i)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  tags = local.vpc_tags
}

module "bastion" {
  for_each = var.bastion_enabled ? local.this : []
  source   = "../../modules/aws-bastion"

  key_name                 = var.key_name
  resource_prefix          = local.cluster_name
  source_security_group_id = module.eks.node_security_group_id
  ssh_cidr_blocks          = var.ssh_cidr_blocks
  subnet_id                = module.vpc.public_subnets.0
  vpc_id                   = module.vpc.vpc_id
}


################################################################################
# Amazon EKS cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  enable_cluster_creator_admin_permissions = true

  # Allow API access from your personal IP.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.ssh_cidr_blocks

  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    (local.cluster_name) = {
      desired_size  = (var.node_group_desired < 1) ? 1 : var.node_group_desired
      iam_role_name = substr(local.cluster_name, 0, 38)
      min_size      = (var.node_group_min < 1) ? 1 : var.node_group_min
    }

    "${local.cluster_name}_controllers" = {
      iam_role_name = local.controllers_role_name
      labels = {
        "jenkins" = "controller"
      }
    }

    "${local.cluster_name}_agents" = {
      iam_role_name = local.agents_role_name
      labels = {
        "jenkins" = "agent"
      }
    }
  }

  eks_managed_node_group_defaults = {
    min_size     = var.node_group_min
    max_size     = var.node_group_max
    desired_size = var.node_group_desired

    ami_type              = "AL2_x86_64"
    capacity_type         = "SPOT"
    create_iam_role       = true
    create_security_group = false
    iam_role_use_name_prefix = false
    instance_types        = var.instance_types
    key_name              = var.key_name
    labels                = {}
    launch_template_tags  = var.tags
    subnet_ids            = module.vpc.private_subnets
  }

  node_security_group_additional_rules = {
    egress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    }

    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_ssh_all = {
      description      = "Egress all SSH to internet for GitHub"
      protocol         = "tcp"
      from_port        = 22
      to_port          = 22
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}


################################################################################
# Amazon Certificate Manager certificate(s)
################################################################################

module "acm_certificate" {
  for_each = var.create_acm_certificate ? local.this : []
  source   = "../../modules/acm-certificate"

  domain_name = var.domain_name
  subdomain   = "*"
}


################################################################################
# Kubernetes resources
################################################################################

module "aws_load_balancer_controller" {
  depends_on = [module.acm_certificate]
  source     = "../../modules/aws-load-balancer-controller"

  aws_account_id            = local.aws_account_id
  aws_region                = local.aws_region
  cluster_name              = local.cluster_name
  cluster_security_group_id = module.eks.cluster_security_group_id
  node_security_group_id    = module.eks.node_security_group_id
  oidc_issuer               = local.oidc_issuer
}

module "cluster_autoscaler" {
  depends_on = [module.eks]
  source     = "../../modules/cluster-autoscaler-eks"

  aws_account_id     = local.aws_account_id
  aws_region         = local.aws_region
  cluster_name       = local.cluster_name
  image_tag          = local.cluster_autoscaler_tag
  oidc_issuer        = local.oidc_issuer
}

module "ebs_driver" {
  depends_on = [module.eks]
  source     = "../../modules/aws-ebs-csi-driver"

  cluster_name      = local.cluster_name
  oidc_issuer       = local.oidc_issuer
  oidc_provider_arn = local.oidc_provider_arn
  volume_tags       = var.tags
}

module "efs_driver" {
  depends_on = [module.eks]
  source     = "../../modules/aws-efs-csi-driver"

  cluster_name           = local.cluster_name
  node_security_group_id = module.eks.node_security_group_id
  oidc_issuer            = local.oidc_issuer
  oidc_provider_arn      = local.oidc_provider_arn
  private_subnet_ids     = module.vpc.private_subnets
  storage_class_uid      = var.storage_class_uid
  vpc_id                 = module.vpc.vpc_id
}

module "external_dns" {
  depends_on = [module.eks]
  source     = "../../modules/external-dns-eks"

  aws_account_id  = local.aws_account_id
  cluster_name    = local.cluster_name
  oidc_issuer     = local.oidc_issuer
  route53_zone_id = data.aws_route53_zone.domain.id
}

module "prometheus" {
  depends_on = [module.aws_load_balancer_controller]
  for_each   = var.install_prometheus ? local.this : []
  source     = "../../modules/prometheus"

  host_name           = "${var.grafana_subdomain}.${var.domain_name}"
  ingress_annotations = local.alb_annotations
  ingress_class_name  = local.ingress_class_name
  ingress_extra_paths = [local.alb_redirect_path]
}

module "cluster_metrics" {
  depends_on = [module.eks]
  source     = "../../modules/metrics-server"
}
