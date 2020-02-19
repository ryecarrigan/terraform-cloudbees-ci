variable "cluster_name" {}
variable "domain_name" {}
variable "key_name" {
  default = ""
}

variable "mysql_database" {}
variable "mysql_password" {}
variable "mysql_user" {}

variable "owner_key" {
  default = "owner"
}

variable "owner_value" {}

variable "ssh_cidr" {}
