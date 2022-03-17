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
    "Master.Image.dockerImage"                   = var.controller_image
    "Agents.Image.dockerImage"                   = var.agent_image
    "Persistence.StorageClass"                   = var.storage_class
  }

  oc_heap_size = "${var.oc_memory / 2}G"
  controller_heap_size = "${var.controller_memory / 2}G"

  values = <<EOT
OperationsCenter:
  CasC:
    Enabled: true

  Platform: ${var.platform}
  HostName: ${var.host_name}
  Protocol: https

  Resources:
    Limits:
      Cpu: ${var.oc_cpu}
      Memory: ${var.oc_memory}G
    Requests:
      Cpu: ${var.oc_cpu}
      Memory: ${var.oc_memory}G

  Ingress:
    Class: ${var.ingress_class}
    Annotations:
      ${indent(6, var.ingress_annotations)}

  ContainerEnv:
    - name: SECRETS
      value: ${var.secret_mount_path}
    - name: MASTER_JAVA_OPTIONS
      value: "-Xms${local.controller_heap_size} -Xmx${local.controller_heap_size} -Dhudson.slaves.NodeProvisioner.initialDelay=0 -XshowSettings:vm -XX:+AlwaysPreTouch -XX:+UseG1GC -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication"

  JavaOpts:
    -Xms${local.oc_heap_size}
    -Xmx${local.oc_heap_size}
    -Dcom.cloudbees.jenkins.cjp.installmanager.CJPPluginManager.enablePluginCatalogInOC=true
    -Dcom.cloudbees.masterprovisioning.kubernetes.KubernetesMasterProvisioning.deleteClaim=true

  ExtraGroovyConfiguration:
    bundles-sync.groovy: |
      def log = java.util.logging.Logger.getLogger('bundles-sync.groovy')
      def job = jenkins.model.Jenkins.get().getItem('casc-bundles-update')
      if (job) {
        log.info('Scheduling bundle sync job')
        def run = jenkins.model.Jenkins.get().getQueue().schedule(job)
        run.future.waitForStart()
        log.info('Bundle sync job starting')
        run.future.get()
        log.info('Bundle sync job completed')
      } else {
        log.warning('CasC bundles sync job does not yet exist')
      }

  ExtraVolumes:
    - name: ${local.secret_name}
      secret:
        defaultMode: 0400
        secretName: ${local.secret_name}

  ExtraVolumeMounts:
    - name: ${local.secret_name}
      mountPath: ${var.secret_mount_path}

Hibernation:
  Enabled: ${var.hibernation_enabled}

EOT
}
