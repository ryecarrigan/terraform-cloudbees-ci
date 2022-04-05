variable "aws_profile" {
  default = null
}

variable "aws_region" {
  default = "us-east-1"
}

variable "bastion_enabled" {
  default = false
  type    = bool
}

variable "cd_subdomain" {}
variable "ci_namespace" {
  default = "cloudbees-ci"
}

variable "ci_subdomain" {}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "cluster_name" {
  default = "terraform-cloudbees-ci"
}

variable "dashboard_subdomain" {
  default = "dashboard"
}

variable "domain_name" {}

variable "grafana_subdomain" {
  default = "grafana"
}

variable "install_cdro" {
  default = false
  type    = bool
}

variable "install_ci" {
  default = false
  type    = bool
}

variable "install_kubernetes_dashboard" {
  default = true
  type    = bool
}

variable "install_prometheus" {
  default = true
  type    = bool
}

variable "instance_types" {
  default = ["m5.xlarge", "m5a.xlarge", "m4.xlarge"]
  type    = set(string)
}

variable "key_name" {
  default = ""
}

variable "kubernetes_version" {
  default = "1.21"
}

variable "ssh_cidr_blocks" {
  default = ["0.0.0.0/32"]
  type    = list(string)
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "zone_count" {
  default = 3
  type    = number

  validation {
    condition     = var.zone_count > 0
    error_message = "Zone count must be non-zero and positive."
  }
}
