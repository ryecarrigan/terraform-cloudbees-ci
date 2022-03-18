# Required variables
variable "ci_host_name" {}
variable "ingress_class" {}
variable "kubeconfig_file" {}

# Common configuration
variable "chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
}

variable "ingress_annotations" {
  default = "{}"
}

variable "platform" {
  default = "standard"
}

# Options for installing and configuring CloudBees CI
variable "install_ci" {
  default = false
  type    = bool
}

variable "ci_chart_version" {
  default = "3.41.6"
}

variable "ci_namespace" {
  default = "cloudbees-ci"
}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "secrets_file" {
  default = "values/secrets.yaml"
}

# Options for installing and configuring CloudBees CD/RO
variable "install_cdro" {
  default = false
  type    = bool
}

variable "cd_admin_password" {
  default = ""
}

variable "cd_chart_version" {
  default = "2.13.2"
}

variable "cd_host_name" {
  default = ""
}

variable "cd_license_file" {
  default = "values/license.xml"
}

variable "cd_namespace" {
  default = "cloudbees-cd"
}

variable "database_endpoint" {
  default = ""
}

variable "database_name" {
  default = "flowdb"
}

variable "database_password" {
  default = ""
}

variable "database_user" {
  default = "flow"
}

variable "rwx_storage_class" {
  default = ""
}

# Options for installing and configuring a MySQL release
variable "install_mysql" {
  default = false
  type    = bool
}

variable "mysql_root_password" {
  default = ""
}
