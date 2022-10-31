variable "bucket_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "k8s_cluster_oidc_arn" {
  type = string
}

variable "region_name" {
  type = string
}

variable "namespace" {
  default = "velero"
  type    = string
}

variable "service_account" {
  default = "velero"
  type    = string
}

variable "release_name" {
  default = "velero"
  type    = string
}

variable "chart_version" {
  default = "2.29.6"
  type    = string
}
