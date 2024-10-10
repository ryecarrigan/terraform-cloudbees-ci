variable "bucket_prefix" {
  type = string
}

variable "bucket_suffix" {
  default = "cbci-cache"
  type    = string
}

variable "iam_roles" {
  type = set(string)
}
