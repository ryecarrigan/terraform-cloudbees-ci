variable "aws_account_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "dns_suffix" {
  default = "amazonaws.com"
  type    = string
}

variable "namespace" {
  default = "kube-system"
}

variable "oidc_issuer" {
  type = string
}

variable "release_name" {
  default = "external-dns"
  type    = string
}

variable "release_version" {
  default = "6.2.1"
}

variable "route53_zone_id" {
  type = string
}

variable "service_account_name" {
  default = "external-dns"
  type    = string
}
