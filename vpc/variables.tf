variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "cluster_name" {}

variable "owner_key" {
  default = "owner"
}

variable "owner_value" {}

variable "zone_count" {
  default = 2
}
