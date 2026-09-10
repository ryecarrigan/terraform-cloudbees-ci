provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = var.tags
  }
}

data "aws_ssm_parameter" "this" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

locals {
  capacity_type          = var.use_spot_instances ? "SPOT" : "ON_DEMAND"
  cluster_name           = "${var.cluster_name}${local.workspace_suffix}"
  this                   = toset(["this"])
  workspace_suffix       = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  agents_group_name      = "${substr(local.cluster_name, 0, 29)}_agents"
  agents_role_name       = substr("${local.cluster_name}-agents", 0, 38)
  controllers_group_name = "${substr(local.cluster_name, 0, 24)}_controllers"
  controllers_role_name  = substr("${local.cluster_name}-controllers", 0, 38)
  default_group_name     = local.default_role_name
  default_role_name      = substr(local.cluster_name, 0, 38)

  eks_managed_node_group_defaults = {
    min_size     = (var.node_group_min < 0) ? 0 : var.node_group_min
    max_size     = var.node_group_max
    desired_size = (var.node_group_desired < 0) ? 0 : var.node_group_desired

    capacity_type            = local.capacity_type
    create_iam_role          = true
    create_security_group    = false
    iam_role_use_name_prefix = false
    instance_types           = var.instance_types
    key_name                 = var.key_name
    labels                   = {}
    launch_template_tags     = var.tags
    metadata_options         = { http_put_response_hop_limit = 2 }
    subnet_ids               = module.vpc.private_subnet_ids
  }

  vpc_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}


################################################################################
# Amazon VPC
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  resource_prefix = local.cluster_name
  vpc_tags        = local.vpc_tags
  zone_count      = var.zone_count
}

module "bastion" {
  for_each = var.bastion_enabled ? local.this : []
  source   = "../../modules/aws-bastion"

  ami_id                   = data.aws_ssm_parameter.this.value
  instance_type            = "t4g.nano"
  key_name                 = var.key_name
  resource_prefix          = local.cluster_name
  source_security_group_id = module.eks.node_security_group_id
  ssh_cidr_blocks          = var.ssh_cidr_blocks
  subnet_id                = coalesce(module.vpc.public_subnet_ids...)
  vpc_id                   = module.vpc.id
}


################################################################################
# Amazon EKS cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = local.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.id

  enable_cluster_creator_admin_permissions = true

  # Allow API access from your personal IP.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.ssh_cidr_blocks

  addons = {
    coredns                = {}
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
  }

  upgrade_policy = {
    support_type = "STANDARD"
  }

  eks_managed_node_groups = {
    (local.default_group_name) = merge(local.eks_managed_node_group_defaults, {
      desired_size  = 1
      iam_role_name = local.default_role_name
      min_size      = 0
    })

    (local.controllers_group_name) = merge(local.eks_managed_node_group_defaults, {
      iam_role_name = local.controllers_role_name
      labels        = { "jenkins" = "controller" }
    })

    (local.agents_group_name) = merge(local.eks_managed_node_group_defaults, {
      capacity_type = "SPOT"
      iam_role_name = local.agents_role_name
      desired_size  = 0
      labels        = { "jenkins" = "agent" }
      min_size      = 0
    })
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
