variable "cluster_name" {
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

variable "tags" {
  default = {}
  type    = map(string)
}
