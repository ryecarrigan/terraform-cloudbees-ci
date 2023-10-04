variable "namespace" {
  default = "kube-system"
  type    = string
}

variable "release_name" {
  default = "metrics-server"
  type    = string
}

variable "release_version" {
  default = "3.11.0"
  type    = string
}
