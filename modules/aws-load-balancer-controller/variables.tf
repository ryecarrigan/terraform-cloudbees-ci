variable "chart_version" {
  default = "3.4.0"
}

variable "cluster_name" {
  type = string
}

variable "gateway_class_name" {
  default = "aws-alb"
  type    = string
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
