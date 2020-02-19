output "instance_role_arn" {
  value = aws_iam_role.instance_role.arn
}

output "eks_cluster_id" {
  value = aws_eks_cluster.cluster.id
}
