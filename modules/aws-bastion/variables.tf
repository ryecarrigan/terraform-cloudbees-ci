variable "extra_tags" {
  default = {}
  type    = map(string)
}

variable "instance_type" {
  default = "t3.nano"
}

variable "key_name" {
  default = ""
}

variable "resource_prefix" {}
variable "ssh_cidr_blocks" {
  type = set(string)
}

variable "source_security_group_id" {}
variable "subnet_id" {}
variable "vpc_id" {}
