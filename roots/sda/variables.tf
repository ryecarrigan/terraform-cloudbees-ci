# Optional common configuration
variable "kubeconfig_file" {
  default = "~/.kube/config"
  type    = string
}

variable "tags" {
  default = {}
  type    = map(string)
}


# Options for installing and configuring CloudBees CI
variable "install_ci" {
  default = false
  type    = bool
}

variable "bundle_dir" {
  default = "oc-casc-bundle"
  type    = string
}

variable "ci_chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
  type    = string
}

variable "ci_chart_version" {
  default = "3.29360.0"
  type    = string
}

variable "ci_host_name" {
  default = ""
  type    = string
}

variable "ci_namespace" {
  default = "cloudbees-ci"
  type    = string
}

variable "ci_values_file" {
  default = "values/ci.yaml"
  type    = string
}

variable "create_service_monitors" {
  default = false
  type    = bool
}

variable "groovy_dir" {
  default = "groovy-init"
  type    = string
}

variable "manage_ci_namespace" {
  default = true
  type    = bool
}

variable "secrets_file" {
  default = "values/secrets.yaml"
  type    = string
}

# Options for installing and configuring CloudBees CD/RO
variable "install_cdro" {
  default = false
  type    = bool
}

variable "cd_chart_version" {
  default = "2.24.1"
  type    = string
}

variable "cd_license_file" {
  default = "values/license.xml"
  type    = string
}

variable "cd_namespace" {
  default = "cloudbees-cd"
  type    = string
}

variable "cd_values_file" {
  default = "values/cd.yaml"
  type    = string
}

variable "manage_cd_namespace" {
  default = true
  type    = bool
}

# Options for installing and configuring a MySQL release
variable "install_mysql" {
  default = false
  type    = bool
}
