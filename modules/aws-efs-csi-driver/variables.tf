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

variable "oidc_arn" {
  type = string
}

variable "private_subnet_ids" {
  default = []
  type    = list(string)
}

variable "release_name" {
  default = "aws-efs-csi-driver"
  type    = string
}

variable "replication_protection" {
  default = true
  type    = bool
}

variable "storage_class_name" {
  default = "efs-sc"
  type    = string
}

variable "storage_class_gid" {
  default = "1000"
  type    = string
}

variable "storage_class_uid" {
  default = "1000"
  type    = string
}

variable "vpc_id" {
  type = string
}
