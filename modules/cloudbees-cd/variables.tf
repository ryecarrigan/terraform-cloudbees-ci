variable "chart_version" {
  default = null
  type    = string
}

variable "license_data" {}

variable "manage_namespace" {
  default = false
  type    = bool
}

variable "namespace" {
  default = "cloudbees-cd"
}

variable "release_name" {
  default = "cloudbees-cd"
}

variable "values" {
  default = []
  type    = list(string)
}
