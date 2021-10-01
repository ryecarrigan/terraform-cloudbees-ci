resource "aws_efs_file_system" "efs_file_system" {
  tags = var.extra_tags
}

resource "aws_efs_mount_target" "efs_mount_target" {
  for_each        = toset(module.eks_vpc.private_subnets)
  file_system_id  = aws_efs_file_system.efs_file_system.id
  security_groups = [aws_security_group.efs.id]
  subnet_id       = each.value
}
