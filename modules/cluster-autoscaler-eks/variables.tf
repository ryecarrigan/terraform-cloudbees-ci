variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "oidc_arn" {
  type = string
}

variable "release_name" {
  default = "cluster-autoscaler"
}

variable "release_version" {
  default = "9.48.0"
}

variable "service_account_name" {
  default = "cluster-autoscaler"
}
