variable "aws_region" {}
variable "aws_account_id" {}
variable "cluster_name" {}

variable "extra_tags" {
  default = {}
  type    = map(string)
}

variable "is_default" {
  default = false
  type    = bool
}

variable "namespace" {
  default = "kube-system"
}

variable "oidc_issuer" {}
variable "oidc_provider_arn" {}
variable "private_subnet_ids" {
  type = list(string)
}

variable "release_name" {
  default = "aws-efs-csi-driver"
}

variable "release_version" {
  default = "2.2.4"
}

variable "service_account_name" {
  default = "aws-efs-csi-driver"
}

variable "source_security_group_id" {}

variable "storage_class_name" {
  default = "efs"
}

variable "vpc_id" {}
