output "bastion_eip" {
  value = var.bastion_enabled ? module.bastion["this"].bastion_eip : ""
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_filename" {
  value = local.kubeconfig_file
}

output "storage_class_name" {
  value = module.efs_driver.storage_class_name
}
