output "bastion_eip" {
  value = var.bastion_enabled ? module.bastion["this"].bastion_eip : ""
}

output "kubeconfig_filename" {
  value = local.kubeconfig_file
}
