module "cloudbees_cd" {
  source = "../../modules/cloudbees-cd"

  admin_password          = var.cd_admin_password
  aws_acm_certificate_arn = var.cd_acm_certificate_arn
  ci_host_name            = "http://${var.ci_host_name}"
  host_name               = var.cd_host_name
  ingress_class           = "nginx"
  license_data            = local.cd_license_data
  mysql_database          = var.mysql_database
  mysql_endpoint          = module.mysql[0].dns_name
  mysql_password          = var.mysql_password
  mysql_user              = var.mysql_user
  namespace               = var.cd_namespace
  platform                = var.platform
  rwx_storage_class       = "efs"
}

module "cloudbees_ci" {
  source = "../../modules/cloudbees-ci"

  bundle_data         = local.oc_bundle_data
  chart_version       = var.ci_chart_version
  host_name           = var.ci_host_name
  ingress_annotations = var.ci_ingress_annotations
  ingress_class       = var.ci_ingress_class
  namespace           = var.ci_namespace
  oc_configmap_name   = var.oc_configmap_name
  platform            = var.platform
  secret_data         = local.oc_secret_data
}

module "mysql" {
  count  = var.install_mysql ? 1 : 0
  source = "../../modules/mysql"

  database_name = var.mysql_database
  password      = var.mysql_password
  root_password = var.mysql_root_password
  user_name     = var.mysql_user
}

locals {
  cd_license_data = fileexists(local.cd_license_file) ? file(local.cd_license_file) : ""
  cd_license_file = "${path.module}/${var.cd_license_file}"
  oc_bundle_data  =  { for file in fileset(local.oc_bundle_dir, "*.{yml,yaml}") : file => file("${local.oc_bundle_dir}/${file}") }
  oc_bundle_dir   = "${path.module}/oc-casc-bundle"
  oc_secret_data  = fileexists(var.secrets_file) ? yamldecode(file(var.secrets_file)) : {}
}
