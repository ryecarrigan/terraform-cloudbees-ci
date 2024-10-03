variable "cidr_block" {
  default = "10.0.0.0/16"
  type    = string

  validation {
    condition     = try(cidrhost(var.cidr_block, 0), null) != null
    error_message = "CIDR block was not in a valid CIDR format."
  }
}

variable "private_subnet_tags" {
  default = {}
  type    = map(string)
}

variable "public_subnet_tags" {
  default = {}
  type    = map(string)
}

variable "resource_prefix" {
  type = string
}

variable "vpc_tags" {
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
