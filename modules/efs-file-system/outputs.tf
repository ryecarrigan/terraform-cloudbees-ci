output "file_system_id" {
  value = aws_efs_file_system.this.id
}

output "iam_policy_arn" {
  value = aws_iam_policy.this.arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}
