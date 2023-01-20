provider "kubernetes" {
  config_path = var.kubeconfig_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_file
  }
}

locals {
  load_balancer_tags = join(",", [for k, v in var.tags : "${k}=${v}"])

  ingress_annotations = lookup({
    alb = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/tags"        = local.load_balancer_tags
      "alb.ingress.kubernetes.io/target-type" = "ip"
    },
  }, var.ingress_class, {})
}


################################################################################
# CloudBees CD/RO
################################################################################

locals {
  install_cdro    = alltrue([var.install_cdro, local.mysql_endpoint != "", var.cd_admin_password != "", var.cd_host_name != "", var.rwx_storage_class != ""])
  cd_license_data = fileexists(local.cd_license_file) ? file(local.cd_license_file) : ""
  cd_license_file = "${path.module}/${var.cd_license_file}"
  mysql_endpoint  = local.install_mysql ? concat(module.mysql.*.dns_name, [""])[0] : var.database_endpoint
}

module "cloudbees_cd" {
  count  = local.install_cdro ? 1 : 0
  source = "../../modules/cloudbees-cd"

  admin_password      = var.cd_admin_password
  chart_version       = var.cd_chart_version
  cjoc_url            = "http://${coalesce(module.cloudbees_ci.*.cjoc_url)}"
  database_endpoint   = local.mysql_endpoint
  database_name       = var.database_name
  database_password   = var.database_password
  database_user       = var.database_user
  host_name           = var.cd_host_name
  ingress_annotations = local.ingress_annotations
  ingress_class       = var.ingress_class
  license_data        = local.cd_license_data
  namespace           = var.cd_namespace
  platform            = var.platform
  rwx_storage_class   = var.rwx_storage_class
}


################################################################################
# CloudBees CI
################################################################################

locals {
  install_ci     = alltrue([var.install_ci, var.ci_host_name != ""])
  bundle_data    = { for file in fileset(local.bundle_dir, "*.{yml,yaml}") : file => file("${local.bundle_dir}/${file}") }
  bundle_dir     = "${path.module}/${var.bundle_dir}"
  ci_values      = fileexists(local.ci_values_file) ? file(local.ci_values_file) : null
  ci_values_file = "${path.module}/${var.ci_values_file}"
  groovy_data    = { for file in fileset(local.groovy_dir, "*.groovy") : file => file("${local.groovy_dir}/${file}") }
  groovy_dir     = "${path.module}/${var.groovy_dir}"
  secret_data    = fileexists(var.secrets_file) ? yamldecode(file(var.secrets_file)) : {}

  prometheus_relabelings = lookup({
    eks = [{
      action       = "replace"
      replacement  = "/$${1}/prometheus/"
      sourceLabels = ["__meta_kubernetes_endpoints_name"]
      targetLabel  = "__metrics_path__"
    }]
  }, var.platform, [])
}

module "cloudbees_ci" {
  count  = local.install_ci ? 1 : 0
  source = "../../modules/cloudbees-ci"

  bundle_data                = local.bundle_data
  bundle_configmap_name      = var.oc_configmap_name
  chart_version              = var.ci_chart_version
  create_servicemonitors     = var.create_servicemonitors
  extra_groovy_configuration = local.groovy_data
  host_name                  = var.ci_host_name
  ingress_annotations        = local.ingress_annotations
  ingress_class              = var.ingress_class
  manage_namespace           = var.manage_ci_namespace
  namespace                  = var.ci_namespace
  platform                   = var.platform
  prometheus_relabelings     = local.prometheus_relabelings
  secret_data                = local.secret_data
  values                     = local.ci_values
}


################################################################################
# MySQL (for CD/RO)
################################################################################

locals {
  install_mysql = alltrue([var.install_mysql, var.database_password != "", var.mysql_root_password != ""])
}

module "mysql" {
  count  = local.install_mysql ? 1 : 0
  source = "../../modules/mysql"

  database_name = var.database_name
  password      = var.database_password
  root_password = var.mysql_root_password
  user_name     = var.database_user
}


################################################################################
# Post-provisioning commands
################################################################################

resource "null_resource" "update_kubeconfig" {
  count      = var.update_kubeconfig ? 1 : 0
  depends_on = [module.cloudbees_ci]

  provisioner "local-exec" {
    command = "kubectl config set-context --current --namespace=${var.ci_namespace}"
    environment = {
      KUBECONFIG = var.kubeconfig_file
    }
  }
}
