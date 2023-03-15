variable "bundle_data" {
  default = {}
  type    = map(any)
}

variable "chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
}

variable "chart_version" {
  default = null
  type    = string
}

variable "create_secrets_role" {
  default = false
  type    = bool
}

variable "create_servicemonitors" {
  default = false
  type    = bool
}

variable "manage_namespace" {
  default = false
  type    = bool
}

variable "namespace" {
  type = string
}

variable "prometheus_relabelings" {
  default = []
  type    = list(any)
}

variable "secret_data" {
  default = {}
  type    = map(any)
}

variable "secret_name" {
  default = "oc-secrets"
  type    = string
}

variable "secrets_role_name" {
  default = "jenkins-secrets"
  type    = string
}

variable "values" {
  default = null
  type    = string
}
