variable "cluster_name" {
  type = string
}

variable "ensure_unique_directory" {
  default = true
  type    = bool
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

variable "reuse_access_point" {
  default = false
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

variable "sub_path_pattern" {
  default = "$${.PV.name}"
  type    = string
}

variable "vpc_id" {
  type = string
}
