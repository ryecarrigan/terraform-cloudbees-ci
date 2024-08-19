variable "chart_version" {
  default = "1.8.2"
}

variable "cluster_name" {
  type = string
}

variable "oidc_arn" {
  type = string
}

variable "release_name" {
  default = "aws-load-balancer-controller"
  type    = string
}

variable "service_account_name" {
  default = "aws-load-balancer-controller"
  type    = string
}
