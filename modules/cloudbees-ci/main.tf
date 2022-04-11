resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  chart      = "cloudbees-core"
  name       = "cloudbees-ci"
  namespace  = var.namespace
  repository = var.chart_repository
  values     = [local.values]
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
  metadata {
    name      = var.oc_configmap_name
    namespace = var.namespace
  }

  data = var.bundle_data
}

resource "kubernetes_secret" "secrets" {
  metadata {
    name      = var.oc_secret_name
    namespace = var.namespace
  }

  data = var.secret_data
}

resource "kubernetes_manifest" "service_monitor" {
  for_each = { for k, v in local.service_monitors : k => v if (var.prometheus_labels != null) }

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

  oc_heap_size         = "${var.oc_memory / 2}G"
  controller_heap_size = "${var.controller_memory / 2}G"

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
      CasC = {
        Enabled = true
      }

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

      ContainerEnv = [
        {
          name  = "SECRETS"
          value = var.secret_mount_path
        },
        {
          name  = "MASTER_JAVA_OPTIONS"
          value = "-Xms${local.controller_heap_size} -Xmx${local.controller_heap_size} -Dhudson.slaves.NodeProvisioner.initialDelay=0 -XshowSettings:vm -XX:+AlwaysPreTouch -XX:+UseG1GC -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication"
        },
      ]

      JavaOpts = "-Xms${local.oc_heap_size} -Xmx${local.oc_heap_size} -Dcom.cloudbees.jenkins.cjp.installmanager.CJPPluginManager.enablePluginCatalogInOC=true -Dcom.cloudbees.masterprovisioning.kubernetes.KubernetesMasterProvisioning.deleteClaim=true"

      ExtraGroovyConfiguration = var.extra_groovy_configuration

      ExtraVolumes = [
        {
          name = var.oc_secret_name
          secret = {
            defaultMode = 0400
            secretName  = var.oc_secret_name
          }
        }
      ]

      ExtraVolumeMounts = [
        {
          name      = var.oc_secret_name
          mountPath = var.secret_mount_path
        }
      ]
    }

    HibernationEnabled = var.hibernation_enabled
  })
}
