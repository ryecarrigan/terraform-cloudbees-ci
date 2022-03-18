module "cloudbees_cd" {
  count  = local.install_cdro ? 1 : 0
  source = "../../modules/cloudbees-cd"

  admin_password      = var.cd_admin_password
  chart_version       = var.cd_chart_version
  ci_oc_url           = local.ci_oc_url
  database_endpoint   = local.mysql_endpoint
  database_name       = var.database_name
  database_password   = var.database_password
  database_user       = var.database_user
  host_name           = var.cd_host_name
  ingress_annotations = var.ingress_annotations
  ingress_class       = var.ingress_class
  license_data        = local.cd_license_data
  namespace           = var.cd_namespace
  platform            = var.platform
  rwx_storage_class   = var.rwx_storage_class
}

module "cloudbees_ci" {
  count  = local.install_ci ? 1 : 0
  source = "../../modules/cloudbees-ci"

  bundle_data         = local.oc_bundle_data
  chart_version       = var.ci_chart_version
  controller_cpu      = 2
  controller_memory   = 8
  host_name           = var.ci_host_name
  ingress_annotations = var.ingress_annotations
  ingress_class       = var.ingress_class
  oc_cpu              = 2
  oc_memory           = 4
  namespace           = var.ci_namespace
  oc_configmap_name   = var.oc_configmap_name
  platform            = var.platform
  secret_data         = local.oc_secret_data
}

module "mysql" {
  count  = local.install_mysql ? 1 : 0
  source = "../../modules/mysql"

  database_name = var.database_name
  password      = var.database_password
  root_password = var.mysql_root_password
  user_name     = var.database_user
}

locals {
  cd_license_data = fileexists(local.cd_license_file) ? file(local.cd_license_file) : ""
  cd_license_file = "${path.module}/${var.cd_license_file}"
  ci_oc_url       = var.ci_host_name == "" ? "" : "http://${var.ci_host_name}/cjoc"
  install_cdro    = alltrue([var.install_cdro, local.mysql_endpoint != "", var.cd_admin_password != "", var.cd_host_name != "", var.rwx_storage_class != ""])
  install_ci      = alltrue([var.install_ci])
  install_mysql   = alltrue([var.install_mysql, var.database_password != "", var.mysql_root_password != ""])
  mysql_endpoint  = local.install_mysql ? concat(module.mysql.*.dns_name, [""])[0] : var.database_endpoint
  oc_bundle_data  =  { for file in fileset(local.oc_bundle_dir, "*.{yml,yaml}") : file => file("${local.oc_bundle_dir}/${file}") }
  oc_bundle_dir   = "${path.module}/oc-casc-bundle"
  oc_secret_data  = fileexists(var.secrets_file) ? yamldecode(file(var.secrets_file)) : {}
}
