variable "cluster_name" {
  type = string
}

variable "oidc_arn" {
  type = string
}

variable "release_name" {
  default = "aws-ebs-csi-driver"
  type    = string
}

variable "storage_class_name" {
  default = "ebs-sc"
  type    = string
}

variable "volume_tags" {
  default = {}
  type    = map(string)
}
