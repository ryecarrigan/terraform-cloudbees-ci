variable "agent_image" {
  default = ""
  type    = string
}

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
  type   = string
}

variable "controller_image" {
  default = ""
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

variable "hibernation_enabled" {
  type    = bool
  default = false
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

variable "cjoc_image" {
  default = ""
  type    = string
}

variable "cpu_request" {
  default = 2
  type    = number
}

variable "memory_request" {
  default = 4
  type    = number
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

variable "secret_mount_path" {
  default = "/var/run/secrets/cjoc"
}

variable "secret_name" {
  default = "oc-secrets"
}

variable "storage_class" {
  default = ""
}
