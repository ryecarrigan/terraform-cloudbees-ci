variable "chart_version" {
  default = "7.1.3"
  type    = string
}

variable "cluster_name" {
  type = string
}

variable "force_destroy_bucket" {
  default = false
  type    = bool
}

variable "namespace" {
  default = "velero"
  type    = string
}

variable "oidc_arn" {
  type = string
}

variable "plugin_image_tag" {
  default = "v1.3.0"
  type    = string
}

variable "release_name" {
  default = "velero"
  type    = string
}

variable "service_account_name" {
  default = "velero"
  type    = string
}
