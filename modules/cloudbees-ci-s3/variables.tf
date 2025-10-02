variable "bucket_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "force_destroy" {
  default = true
  type    = bool
}

variable "instance_role_name" {
  default = ""
  type    = string
}

variable "namespace" {
  type = string
}

variable "service_account_name" {
  default = ""
  type    = string
}
