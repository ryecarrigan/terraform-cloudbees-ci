provider "kubernetes" {
  config_path = var.kubeconfig_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_file
  }
}


################################################################################
# CloudBees CD/RO
################################################################################

locals {
  install_cdro    = alltrue([var.install_cdro, local.mysql_endpoint != ""])
  cd_license_data = fileexists(local.cd_license_file) ? file(local.cd_license_file) : ""
  cd_license_file = "${path.module}/${var.cd_license_file}"
  cd_values      = fileexists(local.cd_values_file) ? file(local.cd_values_file) : null
  cd_values_yaml = yamldecode(local.cd_values)
  cd_values_file = "${path.module}/${var.cd_values_file}"
  mysql_endpoint = var.install_mysql ? concat(module.mysql.*.dns_name, [""])[0] : lookup(lookup(local.cd_values_yaml, "database", {}), "clusterEndpoint", "")
  mysql_values   = yamlencode({
    database: {
      clusterEndpoint: local.mysql_endpoint
    }
  })
}

module "cloudbees_cd" {
  count  = local.install_cdro ? 1 : 0
  source = "../../modules/cloudbees-cd"

  chart_version       = var.cd_chart_version
  license_data        = local.cd_license_data
  manage_namespace    = var.manage_cd_namespace
  namespace           = var.cd_namespace
  values              = [local.cd_values, local.mysql_values]
}


################################################################################
# CloudBees CI
################################################################################

locals {
  install_ci     = alltrue([var.install_ci, var.ci_host_name != ""])
  ci_values      = fileexists(local.ci_values_file) ? file(local.ci_values_file) : null
  ci_values_file = "${path.module}/${var.ci_values_file}"
  groovy_data    = { for file in fileset(local.groovy_dir, "*.groovy") : file => file("${local.groovy_dir}/${file}") }
  groovy_dir     = "${path.module}/${var.groovy_dir}"
  secret_data    = fileexists(var.secrets_file) ? yamldecode(file(var.secrets_file)) : {}
}

module "cloudbees_ci" {
  count  = local.install_ci ? 1 : 0
  source = "../../modules/cloudbees-ci"

  chart_version           = var.ci_chart_version
  create_service_monitors = var.create_service_monitors
  create_secrets_role     = true
  manage_namespace        = var.manage_ci_namespace
  namespace               = var.ci_namespace
  secret_data             = local.secret_data
  values                  = local.ci_values
}


################################################################################
# MySQL (for CD/RO)
################################################################################

locals {
  db_password   = lookup(local.db_values, "dbPassword")
  db_values     = lookup(local.cd_values_yaml, "database")
  install_mysql = alltrue([var.install_mysql, local.db_password != ""])
}

module "mysql" {
  count  = local.install_mysql ? 1 : 0
  source = "../../modules/mysql"

  database_name = lookup(local.db_values, "dbName", "flowdb")
  password      = local.db_password
  root_password = local.db_password
  user_name     = lookup(local.db_values, "dbUser", "flow")
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
