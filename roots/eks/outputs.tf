output "autoscaling_group_names" {
  value = concat(module.eks.eks_managed_node_groups_autoscaling_group_names, module.eks.self_managed_node_groups_autoscaling_group_names)
}

output "bastion_eip" {
  value = var.bastion_enabled ? module.bastion["this"].bastion_eip : ""
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "efs_filesystem_id" {
  value = module.efs_driver.file_system_id
}

output "kubeconfig_filename" {
  value = local.kubeconfig_file
}

output "nat_public_ip" {
  value = module.vpc.nat_public_ip
}

output "storage_class_name" {
  value = module.efs_driver.storage_class_name
}

output "velero_bucket" {
  value = module.velero.bucket_name
}
