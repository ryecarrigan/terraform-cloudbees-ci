variable "cluster_name" {
  type = string
}

variable "encrypt_file_system" {
  default = true
  type    = bool
}

variable "kms_key_id" {
  default = null
  type    = string
}

variable "node_security_group_id" {
  type = string
}

variable "oidc_issuer" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "partition_dns" {
  default = "amazonaws.com"
  type    = string
}

variable "partition_id" {
  default = "aws"
  type    = string
}

variable "private_subnet_ids" {
  default = []
  type    = list(string)
}

variable "release_name" {
  default = "aws-efs-csi-driver"
}

variable "release_version" {
  default = "2.4.7"
}

variable "storage_class_name" {
  default = "efs-sc"
  type    = string
}

variable "storage_class_uid" {
  default = "1000"
  type    = string
}

variable "vpc_id" {
  type = string
}
