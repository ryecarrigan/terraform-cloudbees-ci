variable "aws_profile" {
  default = ""
  type    = string
}

variable "name_prefix" {
  type = string
}

variable "primary_region" {
  default = "us-east-1"
  type    = string
}

variable "primary_workspace" {
  type = string
}

variable "replication_rule_id" {
  default = "velero"
  type    = string
}

variable "remote_state_backend" {
  default = "s3"
  type    = string
}

variable "remote_state_config" {
  type = map(string)
}

variable "secondary_region" {
  default = "us-west-1"
  type    = string
}

variable "secondary_workspace" {
  type = string
}

variable "tags" {
  default = {}
  type    = map(string)
}
