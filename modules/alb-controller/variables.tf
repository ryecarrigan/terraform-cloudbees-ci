variable "aws_region" {}
variable "cluster_name" {}

variable "extra_tags" {
  default = {}
  type    = map(string)
}

variable "namespace" {
  default = "kube-system"
}

variable "oidc_issuer" {}
variable "oidc_provider_arn" {}
variable "release_name" {
  default = "aws-load-balancer-controller"
}

variable "release_version" {
  default = "1.3.3"
}

variable "service_account_name" {
  default = "aws-load-balancer-controller"
}
