# Required variables
variable "cluster_name" {
  type = string
}

variable "domain_name" {
  type = string
}

# Optional variables
variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "bastion_enabled" {
  default = false
  type    = bool
}

variable "ci_namespace" {
  default = "cloudbees-ci"
  type    = string
}

variable "cidr_block" {
  default = "10.0.0.0/16"
  type    = string

  validation {
    condition     = try(cidrhost(var.cidr_block, 0), null) != null
    error_message = "CIDR block was not in a valid CIDR format."
  }
}

variable "cluster_autoscaler_tag" {
  default = "v1.32.1"
  type    = string
}

variable "create_acm_certificate" {
  default = true
  type    = bool
}

variable "create_kubeconfig_file" {
  default = true
  type    = bool
}

variable "create_s3_bucket" {
  default = false
  type    = bool
}

variable "efs_replication_protection" {
  default = true
  type    = bool
}

variable "grafana_subdomain" {
  default = "grafana"
  type    = string
}

variable "install_prometheus" {
  default = false
  type    = bool
}

variable "instance_types" {
  default = ["m5.xlarge", "m5a.xlarge", "m6a.xlarge", "m7a.xlarge"]
  type    = set(string)
}

variable "key_name" {
  default = ""
  type    = string
}

variable "kubeconfig_file" {
  default = "eks_kubeconfig"
  type    = string
}

variable "kubernetes_version" {
  default = "1.32"
  type    = string
}

variable "node_group_desired" {
  default = 1
  type    = number
}

variable "node_group_max" {
  default = 4
  type    = number
}

variable "node_group_min" {
  default = 1
  type    = number
}

variable "single_node_group_per_az" {
  default = true
  type    = bool
}

variable "ssh_cidr_blocks" {
  type = list(string)

  validation {
    condition     = contains([for block in var.ssh_cidr_blocks : try(cidrhost(block, 0), "")], "") == false
    error_message = "List of SSH CIDR blocks contains an invalid CIDR block."
  }
}

variable "storage_class_uid" {
  default = "1000"
  type    = string
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "use_spot_instances" {
  default = false
  type    = bool
}

variable "zone_count" {
  default = 3
  type    = number

  validation {
    condition     = var.zone_count > 0
    error_message = "Zone count must be non-zero and positive."
  }
}
