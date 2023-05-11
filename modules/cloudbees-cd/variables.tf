variable "chart_version" {}
variable "license_data" {}

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
