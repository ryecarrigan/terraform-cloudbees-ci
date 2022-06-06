locals {
  cjoc_rules = try(data.kubernetes_ingress.cjoc.spec[0].rule[0], "")
  cjoc_host  = try(local.cjoc_rules["host"], "")
  cjoc_path  = try([for rule in local.cjoc_rules["http"][0]["path"] : rule["path"] if rule["backend"][0]["service_name"] == "cjoc"][0], "")
}

output "cjoc_url" {
  value = "${local.cjoc_host}${local.cjoc_path}"
}
