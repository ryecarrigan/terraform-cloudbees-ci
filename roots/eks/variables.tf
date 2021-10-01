variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "cluster_name" {}

variable "eks_version" {
  default = "1.21"
}

variable "extra_tags" {
  default = null
  type    = map(string)
}

variable "host_name" {}

variable "instance_types" {
  default = ["m5.xlarge", "m5a.xlarge", "m4.xlarge"]
  type    = set(string)
}

variable "key_name" {
  default = ""
}

variable "nginx_namespace" {
  default = "nginx-ingress"
}

variable "ssh_cidr" {
  default = "0.0.0.0/32"
}

variable "zone_count" {
  default = 3
  type    = number

  validation {
    condition     = var.zone_count > 0
    error_message = "Zone count must be non-zero and positive."
  }
}

variable "zone_name" {
  default = ""
}
