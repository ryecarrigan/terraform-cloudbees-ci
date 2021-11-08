variable "acm_certificate_arn" {
  default = ""
}

variable "agent_image" {
  default = ""
}

variable "bundle_data" {}

variable "chart_repository" {
  default = "https://charts.cloudbees.com/public/cloudbees"
}

variable "chart_version" {
  default = "3.37.2"
}

variable "controller_image" {
  default = ""
}

variable "hibernation_enabled" {
  type    = bool
  default = false
}

variable "host_name" {}

variable "ingress_annotations" {
  type = map(string)
}

variable "ingress_class" {}
variable "namespace" {}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "oc_cpu_request" {
  default = "2"
}

variable "oc_image" {
  default = ""
}

variable "oc_memory_request" {
  default = "4G"
}

variable "oc_secret_name" {
  default = "oc-secrets"
}

variable "secret_mount_path" {
  default = "/var/run/secrets/cjoc"
}

variable "platform" {}

variable "secret_data" {
  default = {}
  type    = map(string)
}

variable "storage_class" {
  default = ""
}
