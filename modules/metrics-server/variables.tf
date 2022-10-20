variable "namespace" {
  default = "kube-system"
  type    = string
}

variable "release_name" {
  default = "metrics-server"
  type    = string
}

variable "release_version" {
  default = "6.0.0"
  type    = string
}
