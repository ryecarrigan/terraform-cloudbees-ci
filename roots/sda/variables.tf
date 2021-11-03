variable "agent_image" {
  default = ""
}

variable "chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
}

variable "chart_version" {
  default = "3.36.4"
}

variable "ci_namespace" {
  default = "cloudbees-ci"
}

variable "controller_image" {
  default = ""
}

variable "domain_name" {}

variable "hibernation_enabled" {
  type    = bool
  default = false
}

variable "manage_namespace" {
  type    = bool
  default = true
}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "oc_image" {
  default = ""
}

variable "oc_secret_name" {
  default = "oc-secrets"
}

variable "oc_secret_path" {
  default = "/var/run/secrets/cjoc"
}

variable "platform" {}

variable "secrets_file" {
  default = "values/secrets.yaml"
}

variable "storage_class" {
  default = ""
}

variable "subdomain" {
  default = ""
}
