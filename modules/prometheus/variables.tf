variable "cloudbees_ci_namespace" {}

variable "host_name" {}
variable "ingress_annotations" {}
variable "ingress_class_name" {}
variable "ingress_extra_paths" {}

variable "namespace" {
  default = "prometheus"
}

variable "release_name" {
  default = "prometheus"
}
