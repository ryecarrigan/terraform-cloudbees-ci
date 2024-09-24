variable "encrypt_file_system" {
  default = true
  type    = bool
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "replication_protection" {
  default = false
  type    = bool
}

variable "resource_prefix" {
  type = string
}

variable "source_security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}
