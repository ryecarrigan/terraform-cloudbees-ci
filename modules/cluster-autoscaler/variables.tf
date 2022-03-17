variable "cluster_name" {}

variable "kubernetes_version" {}

variable "namespace" {
  default = "kube-system"
}

variable "oidc_provider_arn" {}
variable "oidc_issuer" {}
variable "patch_version" {
  default = 0
}

variable "release_name" {
  default = "cluster-autoscaler"
}

variable "service_account_name" {
  default = "cluster-autoscaler"
}

variable "worker_asg_arns" {}
