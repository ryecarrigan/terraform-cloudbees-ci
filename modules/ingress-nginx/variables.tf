variable "acm_certificate_arn" {}

variable "load_balancer_source_ranges" {
  default = []
  type    = set(string)
}

variable "namespace" {
  default = "ingress-nginx"
}
