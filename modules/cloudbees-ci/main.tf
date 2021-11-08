locals {
  namespace_name = kubernetes_namespace.this.metadata[0].name
  secret_name    = kubernetes_secret.secrets.metadata[0].name
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  chart      = "cloudbees-core"
  name       = "cloudbees-ci"
  namespace  = local.namespace_name
  repository = var.chart_repository
  values     = [lookup(local.values_files, var.platform), local.ingress_values, local.secret_values]
  version    = var.chart_version

  set {
    name  = "OperationsCenter.HostName"
    value = var.host_name
  }

  # Dynamically set values if the associated vars are set
  dynamic "set" {
    for_each = local.dynamic_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "kubernetes_config_map" "casc_bundle" {
  metadata {
    name      = var.oc_configmap_name
    namespace = local.namespace_name
  }

  data = var.bundle_data
}

resource "kubernetes_secret" "secrets" {
  metadata {
    name      = var.oc_secret_name
    namespace = local.namespace_name
  }

  data = var.secret_data
}

locals {
  dynamic_values = {for k, v in local.optional_values: k => v if v != ""}
  optional_values = {
    "OperationsCenter.Image.dockerImage"         = var.oc_image
    "OperationsCenter.Platform"                  = var.platform
    "OperationsCenter.Resources.Limits.Cpu"      = var.oc_cpu_request
    "OperationsCenter.Resources.Requests.Cpu"    = var.oc_cpu_request
    "OperationsCenter.Resources.Limits.Memory"   = var.oc_memory_request
    "OperationsCenter.Resources.Requests.Memory" = var.oc_memory_request
    "Master.Image.dockerImage"                   = var.controller_image
    "Agents.Image.dockerImage"                   = var.agent_image
    "Hibernation.Enabled"                        = var.hibernation_enabled
    "Persistence.StorageClass"                   = var.storage_class
  }

  annotation_strings = [for k, v in var.ingress_annotations : "${k}: ${v}"]

  ingress_values = <<EOT
OperationsCenter:
  Ingress:
    Class: ${var.ingress_class}
    Annotations:
      ${join("\n      ", local.annotation_strings)}
EOT

  secret_values = <<EOT
OperationsCenter:
  ContainerEnv:
    - name: SECRETS
      value: ${var.secret_mount_path}
  ExtraVolumes:
    - name: ${local.secret_name}
      secret:
        defaultMode: 0400
        secretName: ${local.secret_name}
  ExtraVolumeMounts:
    - name: ${local.secret_name}
      mountPath: ${var.secret_mount_path}
EOT

  values_files = {
    eks = file("${path.module}/values/eks.yaml")
  }
}
