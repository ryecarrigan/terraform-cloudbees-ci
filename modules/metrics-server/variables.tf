variable "namespace" {
  default = "kube-system"
  type    = string
}

variable "release_name" {
  default = "metrics-server"
  type    = string
}

variable "release_version" {
  default = "6.2.7"
  type    = string
}
