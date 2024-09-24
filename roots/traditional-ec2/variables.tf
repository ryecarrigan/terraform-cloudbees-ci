# Required variables
variable "cluster_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "ssh_cidr_blocks" {
  type = list(string)

  validation {
    condition     = contains([for block in var.ssh_cidr_blocks : try(cidrhost(block, 0), "")], "") == false
    error_message = "List of SSH CIDR blocks contains an invalid CIDR block."
  }
}

# Optional variables
variable "aws_region" {
  default = "us-east-1"
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

variable "instance_type" {
  default = "t4g.small"
  type    = string
}

variable "key_name" {
  default = ""
  type    = string
}

variable "subdomain" {
  default = "trad"
  type    = string
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
