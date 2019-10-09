output "instance_role_arn" {
  value = module.eks.instance_role_arn
}

output "cluster_name" {
  value = var.cluster_name
}
