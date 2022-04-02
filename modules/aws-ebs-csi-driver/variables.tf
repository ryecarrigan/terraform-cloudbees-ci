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

variable "release_name" {
  default = "aws-ebs-csi-driver"
  type    = string
}

variable "release_version" {
  default = "2.6.4"
  type    = string
}

variable "service_account_name" {
  default = "aws-ebs-csi-driver"
  type    = string
}

variable "storage_class_name" {
  default = "ebs"
  type    = string
}

variable "volume_tags" {
  default = {}
  type    = map(string)
}
