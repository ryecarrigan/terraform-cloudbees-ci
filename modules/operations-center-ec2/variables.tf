variable "acm_certificate_arn" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "cluster_security_group_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "efs_file_system_id" {
  type = string
}

variable "efs_iam_policy_arn" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  default = ""
  type    = string
}

variable "public_subnets" {
  type = set(string)
}

variable "private_subnets" {
  type = set(string)
}

variable "resource_prefix" {
  type = string
}

variable "resource_suffix" {
  default = "cjoc"
  type    = string
}

variable "ssh_cidr_blocks" {
  type = set(string)
}

variable "subdomain" {
  type = string
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "vpc_id" {
  type = string
}
