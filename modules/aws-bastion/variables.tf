variable "ami_id" {
  type = string
}

variable "instance_type" {
  default = "t4g.nano"
  type    = string
}

variable "key_name" {
  default = ""
  type    = string
}

variable "resource_prefix" {
  type = string
}

variable "resource_suffix" {
  default = "bastion"
  type    = string
}

variable "ssh_cidr_blocks" {
  type = set(string)
}

variable "source_security_group_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "vpc_id" {
  type = string
}
