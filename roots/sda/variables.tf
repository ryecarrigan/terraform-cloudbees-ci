variable "cd_acm_certificate_arn" {
  default = ""
}

variable "cd_admin_password" {}
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
  default = "3.37.2"
}

variable "ci_host_name" {}

variable "ci_ingress_annotations" {
  default = {
    "alb.ingress.kubernetes.io/scheme" = "internet-facing"
  }

  type = map(string)
}

variable "ci_ingress_class" {
  default = "alb"
}

variable "ci_namespace" {
  default = "cloudbees-ci"
}

variable "domain_name" {}

variable "install_mysql" {
  type    = bool
  default = false
}

variable "mysql_database" {
  default = "flowdb"
}

variable "mysql_password" {}

variable "mysql_root_password" {
  default = ""
}

variable "mysql_user" {
  default = "flow"
}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "platform" {}

variable "secrets_file" {
  default = "values/secrets.yaml"
}
