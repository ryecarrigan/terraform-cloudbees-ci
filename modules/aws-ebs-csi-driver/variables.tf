variable "aws_account_id" {}
variable "aws_region" {}
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
variable "release_name" {
  default = "aws-ebs-csi-driver"
}

variable "release_version" {
  default = "2.6.4"
}

variable "service_account_name" {
  default = "aws-ebs-csi-driver"
}

variable "storage_class_name" {
  default = "ebs"
}
