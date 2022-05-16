# Required variables
variable "ingress_class" {
  type = string
}

variable "platform" {
  type = string

  validation {
    condition     = contains(["eks"], var.platform)
    error_message = "Not a tested/supported platform."
  }
}

# Common configuration
variable "kubeconfig_file" {
  default = "~/.kube/config"
  type    = string
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "update_kubeconfig" {
  default = true
  type    = bool
}

# Options for installing and configuring CloudBees CI
variable "install_ci" {
  default = false
  type    = bool
}

variable "agent_image" {
  default = ""
}

variable "create_servicemonitors" {
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
  default = "3.43.1"
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

variable "controller_image" {
  default = ""
  type    = string
}

variable "groovy_dir" {
  default = "groovy-init"
  type    = string
}

variable "manage_ci_namespace" {
  default = true
  type    = bool
}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
  type    = string
}

variable "oc_image" {
  default = ""
  type    = string
}

variable "secrets_file" {
  default = "values/secrets.yaml"
  type    = string
}

variable "storage_class" {
  default = ""
  type    = string
}

# Options for installing and configuring CloudBees CD/RO
variable "install_cdro" {
  default = false
  type    = bool
}

variable "cd_admin_password" {
  default = ""
  type    = string
}

variable "cd_chart_version" {
  default = "2.13.2"
  type    = string
}

variable "cd_host_name" {
  default = ""
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

variable "database_endpoint" {
  default = ""
  type    = string
}

variable "database_name" {
  default = "flowdb"
  type    = string
}

variable "database_password" {
  default = ""
  type    = string
}

variable "database_user" {
  default = "flow"
  type    = string
}

variable "rwx_storage_class" {
  default = ""
  type    = string
}

# Options for installing and configuring a MySQL release
variable "install_mysql" {
  default = false
  type    = bool
}

variable "mysql_root_password" {
  default = ""
  type    = string
}
