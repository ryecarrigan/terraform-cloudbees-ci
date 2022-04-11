variable "agent_image" {
  default = ""
}

variable "bundle_data" {
  default = {}
}

variable "chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
}

variable "chart_version" {}

variable "controller_cpu" {
  default = 2
  type    = number
}

variable "controller_image" {
  default = ""
}

variable "controller_memory" {
  default = 8
  type    = number
}

variable "extra_groovy_configuration" {
  default = {}
}

variable "hibernation_enabled" {
  type    = bool
  default = false
}

variable "host_name" {}

variable "ingress_annotations" {}
variable "ingress_class" {}
variable "namespace" {}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "oc_cpu" {
  default = 2
  type    = number
}

variable "oc_image" {
  default = ""
}

variable "oc_memory" {
  default = 4
  type    = number
}

variable "oc_secret_name" {
  default = "oc-secrets"
}

variable "secret_mount_path" {
  default = "/var/run/secrets/cjoc"
}

variable "platform" {
  default = "standard"
}

variable "prometheus_labels" {
  default = null
  type    = map(string)
}

variable "prometheus_relabelings" {
  default = []
  type    = list(any)
}

variable "secret_data" {
  default = {}
  type    = map(string)
}

variable "storage_class" {
  default = ""
}
