variable "bundle_configmap_name" {
  default = "oc-casc-bundle"
}

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

variable "create_servicemonitors" {
  default = false
  type    = bool
}

variable "extra_groovy_configuration" {
  default = {}
  type    = map(any)
}

variable "host_name" {
  type = string
}

variable "ingress_annotations" {
  type = map(any)
}

variable "ingress_class" {
  type    = string
}

variable "manage_namespace" {
  default = false
  type    = bool
}

variable "namespace" {
  type = string
}

variable "platform" {
  default = "standard"
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
}

variable "values" {
  default = null
  type    = string
}
