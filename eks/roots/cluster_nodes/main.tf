terraform {
  backend "s3" {
    key = "cloudbees_ci/cluster_nodes/terraform.tfstate"
  }
}

provider "aws" {}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_auth_token
  load_config_file       = false
}

variable "bucket_name" {}
variable "cluster_name" {}
variable "eks_version" {}
variable "extra_tags" {
  default = {}
  type    = map(string)
}

variable "instance_types" {
  default = ["m5.large", "m5a.large", "m4.large"]
  type    = set(string)
}

variable "key_name" {
  default = ""
}

variable "linux_asg_names" {
  default = ["linux-0"]
  type    = set(string)
}

variable "windows_asg_names" {
  default = []
  type    = set(string)
}

resource "kubernetes_config_map" "iam_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = join("\n", concat(local.linux_roles, local.windows_roles))
  }
}

module "eks_linux" {
  for_each = var.linux_asg_names
  source   = "git@github.com:ryecarrigan/terraform-eks-asg.git?ref=v3.0.1"

  autoscaler_enabled = true
  cluster_name       = var.cluster_name
  desired_nodes      = 1
  extra_tags         = var.extra_tags
  image_id           = data.aws_ami.linux_ami.image_id
  instance_types     = var.instance_types
  key_name           = var.key_name
  maximum_nodes      = 8
  minimum_nodes      = 0
  node_name_prefix   = "${var.cluster_name}-${each.value}"
  security_group_ids = [local.security_group_id]
  subnet_ids         = local.subnet_ids
  user_data          = data.template_file.linux_user_data.rendered
}

# Windows nodes untested and not guaranteed!
module "eks_windows" {
  for_each = var.windows_asg_names
  source   = "git@github.com:ryecarrigan/terraform-eks-asg.git?ref=v3.0.1"

  autoscaler_enabled   = false
  cluster_name         = var.cluster_name
  desired_nodes        = 0
  extra_tags           = var.extra_tags
  image_id             = data.aws_ssm_parameter.windows_ami.value
  instance_types       = var.instance_types
  maximum_nodes        = 0
  minimum_nodes        = 0
  node_name_prefix     = "${var.cluster_name}-${each.value}"
  security_group_ids   = [local.security_group_id]
  subnet_ids           = local.subnet_ids
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
    values = ["amazon-eks-node-${var.eks_version}-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-${var.eks_version}/image_id"
}

data "template_file" "linux_user_data" {
  template = file("${path.module}/linux_user_data.tpl")
  vars = {
    bootstrap_arguments = ""
    cluster_name        = var.cluster_name
  }
}

data "template_file" "windows_user_data" {
  template = file("${path.module}/windows_user_data.tpl")
  vars = {
    cluster_name = var.cluster_name
  }
}

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    key    = "cloudbees_ci/cluster_setup/terraform.tfstate"
  }
}

locals {
  cluster_auth_token     = data.aws_eks_cluster_auth.auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  kubernetes_host        = data.aws_eks_cluster.cluster.endpoint
  security_group_id      = data.terraform_remote_state.eks_cluster.outputs.node_security_group_id
  subnet_ids             = data.terraform_remote_state.eks_cluster.outputs.private_subnet_ids
}

locals {
  linux_roles = [for name in var.linux_asg_names: <<EOT
- rolearn: ${module.eks_linux[name].node_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOT
  ]

  windows_roles = [for name in var.windows_asg_names: <<EOT
- rolearn: ${module.eks_windows[name].node_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
    - eks:kube-proxy-windows
EOT
  ]
}
