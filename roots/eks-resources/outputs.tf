output "efs_filesystem_id" {
  value = module.efs_driver.file_system_id
}

output "storage_class_name" {
  value = module.efs_driver.storage_class_name
}

output "velero_bucket" {
  value = var.install_velero ? module.velero["this"].bucket_name : ""
}
