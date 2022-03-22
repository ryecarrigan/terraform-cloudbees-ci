output "dns_name" {
  value = "mysql.${var.namespace_name}.svc.cluster.local"
}
