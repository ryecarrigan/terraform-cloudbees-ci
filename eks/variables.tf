locals {
  bastion_user_data = <<EOF
#!/usr/bin/env bash
install() {
  curl -o $1 $2
  chown ec2-user:ec2-user $1
  chmod +x $1
}

install /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl
install /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator

pip install --upgrade awscli
aws eks --region ${local.region_name} update-kubeconfig --name ${var.cluster_name}
EOF

  cluster_name_tag = "kubernetes.io/cluster/${var.cluster_name}"
  linux_prefix = "${var.cluster_name}-linux"
  node_user_data = <<EOF
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name} ${var.bootstrap_arguments}
EOF

  region_name = data.aws_region.current.name
  windows_prefix = "${var.cluster_name}-windows"
  windows_user_data = <<EOF
<powershell>
[string]$EKSBinDir = "$env:ProgramFiles\Amazon\EKS"
[string]$EKSBootstrapScriptName = 'Start-EKSBootstrap.ps1'
[string]$EKSBootstrapScriptFile = "$EKSBinDir\$EKSBootstrapScriptName"
[string]$cfn_signal = "$env:ProgramFiles\Amazon\cfn-bootstrap\cfn-signal.exe"
& $EKSBootstrapScriptFile -EKSClusterName ${var.cluster_name}  3>&1 4>&1 5>&1 6>&1
</powershell>
EOF
}

data "aws_ami" "eks_optimized" {
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

data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}

data "aws_region" "current" {}

variable "bastion_count" {
  default = 0
  type    = number
}

variable "cluster_name" {}
variable "eks_version" {
  default = "1.15"
}

variable "key_name" {}

variable "bootstrap_arguments" {
  default = ""
}

variable "linux_nodes_desired" {
  default = 2
}

variable "linux_nodes_max" {
  default = 4
}

variable "linux_nodes_min" {
  default = 0
}

variable "node_instance_type" {
  default = "m5.large"
}

variable "node_volume_size" {
  default = 50
}

variable "owner_key" {
  default = "owner"
}

variable "owner_value" {}

variable "private_key_file" {}

variable "private_subnet_ids" {
  type = "list"
}
variable "public_subnet_ids" {
  type = "list"
}

variable "ssh_cidr" {}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_id" {}

variable "windows_nodes_desired" {
  default = 0
}

variable "windows_nodes_max" {
  default = 4
}

variable "windows_nodes_min" {
  default = 0
}
