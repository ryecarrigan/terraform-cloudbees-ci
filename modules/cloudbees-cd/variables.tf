variable "admin_password" {}
variable "chart_version" {}
variable "host_name" {}
variable "ingress_annotations" {}
variable "ingress_class" {}
variable "license_data" {}
variable "mysql_database" {}
variable "mysql_endpoint" {}
variable "mysql_password" {}
variable "mysql_user" {}

variable "namespace" {
  default = "cloudbees-cd"
}

variable "ci_oc_url" {}

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
