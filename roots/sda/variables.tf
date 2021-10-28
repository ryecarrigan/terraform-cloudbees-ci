variable "ci_namespace" {
  default = "cloudbees-ci"
}

variable "manage_namespace" {
  type    = bool
  default = true
}

variable "oc_configmap_name" {
  default = "oc-casc-bundle"
}

variable "oc_secret_name" {
  default = "oc-secrets"
}

variable "oc_secret_path" {
  default = "/var/run/secrets/cjoc"
}

variable "cluster_name" {}
variable "host_name" {}
variable "platform" {}
variable "secrets_file" {
  default = "values/secrets.yaml"
}

variable "storage_class" {}
variable "zone_name" {}
