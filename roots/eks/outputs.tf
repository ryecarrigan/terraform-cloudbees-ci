output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_id}"
}

output "update_kubectl_context_command" {
  value = "kubectl config use-context ${module.eks.cluster_arn}"
}
