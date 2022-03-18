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
  default = "external-dns"
}

variable "release_version" {
  default = "6.2.1"
}

variable "route53_zone_id" {}
variable "service_account_name" {
  default = "external-dns"
}
