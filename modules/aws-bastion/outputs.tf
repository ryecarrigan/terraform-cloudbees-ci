output "bastion_eip" {
  value = aws_eip.this.address
}

output "security_group_id" {
  value = aws_security_group.this.id
}
