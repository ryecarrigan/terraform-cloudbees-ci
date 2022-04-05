variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "is_default_class" {
  default = false
  type    = bool
}

variable "node_security_group_id" {
  type = string
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
  default = "efs-csi-controller-sa"
  type    = string
}

variable "storage_class_name" {
  default = "efs-sc"
  type    = string
}

variable "vpc_id" {
  type = string
}
