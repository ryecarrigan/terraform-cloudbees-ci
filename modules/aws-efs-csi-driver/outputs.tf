output "file_system_id" {
  value = module.efs_file_system.file_system_id
}

output "security_group_id" {
  value = module.efs_file_system.security_group_id
}

output "storage_class_name" {
  value = var.storage_class_name
}
