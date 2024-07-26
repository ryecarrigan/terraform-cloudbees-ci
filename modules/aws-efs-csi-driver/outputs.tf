output "security_group_id" {
  value = aws_security_group.this.id
}

output "storage_class_name" {
  value = var.storage_class_name
}
