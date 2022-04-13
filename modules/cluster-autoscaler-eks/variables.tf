variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "oidc_issuer" {
  type = string
}

variable "partition_dns" {
  default = "amazonaws.com"
  type    = string
}

variable "partition_id" {
  default = "aws"
  type    = string
}

variable "patch_version" {
  default = 0
}

variable "release_name" {
  default = "cluster-autoscaler"
}

variable "release_version" {
  default = "9.16.1"
}

variable "service_account_name" {
  default = "cluster-autoscaler"
}
