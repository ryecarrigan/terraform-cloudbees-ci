variable "cd_admin_password" {}
variable "cd_chart_version" {
  default = "2.13.2"
}

variable "cd_host_name" {}

variable "cd_license_file" {
  default = "values/license.xml"
}

variable "cd_namespace" {
  default = "cloudbees-cd"
}

variable "chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
}

variable "ci_chart_version" {
  default = "3.39.9"
}

variable "ci_host_name" {}

variable "ci_namespace" {
  default = "cloudbees-ci"
}

variable "domain_name" {}

variable "ingress_annotations" {
  default = "[]"
}

variable "ingress_class" {
  default = "alb"
}

variable "kubeconfig_file" {}

variable "mysql_database" {
  default = "flowdb"
}

variable "mysql_password" {}
variable "mysql_root_password" {}

variable "mysql_user" {
  default = "flow"
}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "platform" {}
variable "rwx_storage_class" {}

variable "secrets_file" {
  default = "values/secrets.yaml"
}
