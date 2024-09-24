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

output "storage_class_name" {
  value = module.efs_driver.storage_class_name
}

output "velero_bucket" {
  value = module.velero.bucket_name
}
