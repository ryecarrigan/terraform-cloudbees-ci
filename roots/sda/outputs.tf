output "update_kubectl_namespace_command" {
  value = "kubectl config set-context --current --namespace=${var.ci_namespace}"
}
