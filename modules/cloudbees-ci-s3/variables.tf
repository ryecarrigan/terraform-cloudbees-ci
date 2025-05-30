variable "bucket_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "service_account_name" {
  default = "pluggable-storage-service"
  type    = string
}
