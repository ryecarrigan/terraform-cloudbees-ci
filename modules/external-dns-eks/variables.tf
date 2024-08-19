variable "aws_account_id" {
  type = string
}

variable "chart_version" {
  default = "1.14.5"
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  default = "kube-system"
}

variable "oidc_arn" {
  type = string
}

variable "release_name" {
  default = "external-dns"
  type    = string
}

variable "route53_zone_id" {
  type = string
}

variable "service_account_name" {
  default = "external-dns"
  type    = string
}
