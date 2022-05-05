variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
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

variable "release_name" {
  default = "aws-ebs-csi-driver"
  type    = string
}

variable "release_version" {
  default = "2.6.4"
  type    = string
}

variable "service_account_name" {
  default = "ebs-csi-controller-sa"
  type    = string
}

variable "storage_class_name" {
  default = "ebs-sc"
  type    = string
}

variable "volume_tags" {
  default = {}
  type    = map(string)
}
