data "kubernetes_ingress" "cjoc" {
  depends_on = [helm_release.this]

  metadata {
    name      = "cjoc"
    namespace = var.namespace
  }
}

locals {
  create_bundle = length(var.bundle_data) != 0
  create_secret = length(var.secret_data) != 0

  bundle = concat([for values in [local.bundle_values] : local.bundle_values if local.create_bundle], [""])[0]
  bundle_values = yamlencode({
    OperationsCenter = {
      CasC = {
        Enabled = true
      }

      ConfigMapName = var.oc_configmap_name
    }
  })

  secrets = concat([for values in [local.secret_values] : local.secret_values if local.create_secret], [""])[0]
  secret_values = yamlencode({
    OperationsCenter = {
      ContainerEnv = [
        {
          name  = "SECRETS"
          value = var.secret_mount_path
        }
      ]

      ExtraVolumes = [{
        name = var.oc_secret_name
        secret = {
          defaultMode = 0400
          secretName  = var.oc_secret_name
        }
      }]

      ExtraVolumeMounts = [{
        name      = var.oc_secret_name
        mountPath = var.secret_mount_path
      }]
    }
  })
}


resource "time_sleep" "wait" {
  depends_on = [kubernetes_namespace.this]

  destroy_duration = "15s"
}


resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  depends_on = [time_sleep.wait]

  chart      = "cloudbees-core"
  name       = "cloudbees-ci"
  namespace  = var.namespace
  repository = var.chart_repository
  values     = [local.values, local.secrets, local.bundle]
  version    = var.chart_version

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
  for_each = local.create_bundle ? local.this : []

  metadata {
    name      = var.oc_configmap_name
    namespace = var.namespace
  }

  data = var.bundle_data
}

resource "kubernetes_secret" "secrets" {
  for_each = local.create_secret ? local.this : []

  metadata {
    name      = var.oc_secret_name
    namespace = var.namespace
  }

  data = var.secret_data
}

resource "kubernetes_manifest" "service_monitor" {
  for_each = { for k, v in local.service_monitors : k => v if var.create_servicemonitors && (var.prometheus_labels != null) }

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata   = {
      labels    = var.prometheus_labels
      name      = each.key
      namespace = var.namespace
    }

    spec = {
      endpoints = [{
        interval    = "30s"
        port        = "http"
        relabelings = var.prometheus_relabelings
      }]

      namespaceSelector = {
        matchNames = [var.namespace]
      }

      selector = each.value
    }
  }
}

locals {
  dynamic_values = {for k, v in local.optional_values: k => v if v != ""}
  optional_values = {
    "OperationsCenter.Image.dockerImage" = var.oc_image
    "Master.Image.dockerImage"           = var.controller_image
    "Agents.Image.dockerImage"           = var.agent_image
    "Persistence.StorageClass"           = var.storage_class
  }

  service_monitors = {
    cjoc = {
      matchLabels = {
        "app.kubernetes.io/name" = "cloudbees-core"
      }
    },

    controllers = {
      matchExpressions = [{
        key      = "com.cloudbees.cje.type"
        operator = "Exists"
      }]
    }
  }

  this = toset(["this"])

  values = yamlencode({
    OperationsCenter = {
      Platform = var.platform
      HostName = var.host_name
      Protocol = "https"

      Resources = {
        Limits = {
          Cpu    = var.oc_cpu
          Memory = "${var.oc_memory}G"
        }

        Requests = {
          Cpu    = var.oc_cpu
          Memory = "${var.oc_memory}G"
        }
      }

      Ingress = {
        Class       = var.ingress_class
        Annotations = var.ingress_annotations
      }

      JavaOpts = "-Xms${var.oc_memory / 2}g -Xmx${var.oc_memory / 2}g -Dcom.cloudbees.jenkins.cjp.installmanager.CJPPluginManager.enablePluginCatalogInOC=true -Dcom.cloudbees.masterprovisioning.kubernetes.KubernetesMasterProvisioning.deleteClaim=true"

      ExtraGroovyConfiguration = var.extra_groovy_configuration
    }

    HibernationEnabled = var.hibernation_enabled
  })
}
