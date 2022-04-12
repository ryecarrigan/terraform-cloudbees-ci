variable "cluster_name" {
  type = string
}

variable "tags" {
  default = {}
  type    = map(string)
}
