variable "admin_password" {}
variable "chart_version" {}
variable "host_name" {}
variable "ingress_annotations" {}
variable "ingress_class" {}
variable "license_data" {}
variable "database_name" {}
variable "database_endpoint" {}
variable "database_password" {}

variable "database_port" {
  default = 3306
  type    = number
}

variable "database_type" {
  default = "mysql"
}

variable "database_user" {}

variable "namespace" {
  default = "cloudbees-cd"
}

variable "ci_oc_url" {}

variable "platform" {}

variable "release_name" {
  default = "cloudbees-cd"
}

variable "rwx_storage_class" {}
