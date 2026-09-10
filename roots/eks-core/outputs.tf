output "autoscaling_group_names" {
  value = concat(module.eks.eks_managed_node_groups_autoscaling_group_names, module.eks.self_managed_node_groups_autoscaling_group_names)
}

output "bastion_eip" {
  value = var.bastion_enabled ? module.bastion["this"].bastion_eip : ""
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "nat_public_ip" {
  value = module.vpc.nat_public_ip
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "vpc_id" {
  value = module.vpc.id
}
