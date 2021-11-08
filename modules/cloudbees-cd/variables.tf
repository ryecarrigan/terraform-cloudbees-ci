variable "admin_password" {}

variable "aws_acm_certificate_arn" {}

variable "chart_version" {
  default = "2.11.1"
}

variable "host_name" {}
variable "ingress_class" {}
variable "license_data" {}
variable "mysql_database" {}
variable "mysql_endpoint" {}
variable "mysql_password" {}
variable "mysql_user" {}

variable "namespace" {
  default = "cloudbees-cd"
}

variable "platform" {
  validation {
    condition     = contains(["eks"], var.platform)
    error_message = "Not a supported platform."
  }
}

variable "release_name" {
  default = "cloudbees-cd"
}

variable "rwx_storage_class" {}
