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
EOF

  cluster_name_tag = "kubernetes.io/cluster/${var.cluster_name}"
  node_group_name = "${var.cluster_name}-${var.node_group_name}"

  node_user_data = <<EOF
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name} ${var.bootstrap_arguments}
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

variable "cluster_name" {}
variable "eks_version" {
  default = "1.14"
}

variable "key_name" {}

variable "bootstrap_arguments" {
  default = ""
}

variable "node_asg_desired" {
  default = 6
}

variable "node_asg_max_size" {
  default = 8
}

variable "node_asg_min_size" {
  default = 2
}

variable "node_group_name" {
  default = "node-group"
}

variable "node_instance_type" {
  default = "t3.medium"
}

variable "node_volume_size" {
  default = 20
}

variable "owner_key" {
  default = "owner"
}

variable "owner_value" {}

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
