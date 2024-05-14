output "ci_namespace" {
  value = local.install_ci ? module.cloudbees_ci.*.namespace[0] : ""
}
