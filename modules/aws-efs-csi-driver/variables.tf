variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "dns_suffix" {
  default = "amazonaws.com"
  type    = string
}

variable "eks_addon_repository" {
  type = string
}

variable "is_default_class" {
  default = false
  type    = bool
}

variable "oidc_issuer" {
  type = string
}

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
  type    = string
}

variable "source_security_group_id" {
  type = string
}

variable "storage_class_name" {
  default = "efs"
  type    = string
}

variable "vpc_id" {
  type = string
}
