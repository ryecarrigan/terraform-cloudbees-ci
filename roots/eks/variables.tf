# Required variables
variable "cluster_name" {
  type = string
}

variable "domain_name" {
  type = string
}

# Optional variables
variable "bastion_enabled" {
  default = false
  type    = bool
}

variable "cidr_block" {
  default = "10.0.0.0/16"
  type    = string

  validation {
    condition     = try(cidrhost(var.cidr_block, 0), null) != null
    error_message = "CIDR block was not in a valid CIDR format."
  }
}

variable "create_acm_certificate" {
  default = true
  type    = bool
}

variable "create_kubeconfig_file" {
  default = true
  type    = bool
}

variable "dashboard_subdomain" {
  default = "dashboard"
  type    = string
}

variable "grafana_subdomain" {
  default = "grafana"
  type    = string
}

variable "install_kubernetes_dashboard" {
  default = false
  type    = bool
}

variable "install_prometheus" {
  default = false
  type    = bool
}

variable "instance_types" {
  default = ["m5.xlarge", "m5a.xlarge", "m4.xlarge"]
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
  default = "1.21"
  type    = string

  validation {
    condition     = contains(["1.19", "1.20", "1.21", "1.22"], var.kubernetes_version)
    error_message = "Provided Kubernetes version is not supported by EKS and/or CloudBees."
  }
}

variable "ssh_cidr_blocks" {
  default = ["0.0.0.0/32"]
  type    = list(string)

  validation {
    condition     = contains([for block in var.ssh_cidr_blocks : try(cidrhost(block, 0), "")], "") == false
    error_message = "List of SSH CIDR blocks contains an invalid CIDR block."
  }
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "update_default_storage_class" {
  default = true
  type    = string
}

variable "zone_count" {
  default = 3
  type    = number

  validation {
    condition     = var.zone_count > 0
    error_message = "Zone count must be non-zero and positive."
  }
}

variable "install_velero" {
  default = false
  type    = bool
}
