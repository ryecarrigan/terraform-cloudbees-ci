resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_namespace.this]

  chart      = "kube-prometheus-stack"
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values     = [local.values]
}

locals {
  values = <<EOT
prometheus:
  additionalServiceMonitors:
    - name: cloudbees
      selector:
        matchExpressions:
          - key: com.cloudbees.cje.type
            operator: Exists
      namespaceSelector:
        matchNames:
          - ${var.cloudbees_ci_namespace}
      endpoints:
        - port: http
          interval: 30s
          relabelings:
            - replacement: /$${1}/prometheus/
              sourceLabels:
                - __meta_kubernetes_endpoints_name
              targetLabel: __metrics_path__
    - name: cjoc
      selector:
        matchLabels:
          app.kubernetes.io/name: cloudbees-core
      namespaceSelector:
        matchNames:
          - ${var.cloudbees_ci_namespace}
      endpoints:
        - port: http
          interval: 30s
          relabelings:
            - replacement: /$${1}/prometheus/
              sourceLabels:
                - __meta_kubernetes_endpoints_name
              targetLabel: __metrics_path__

grafana:
  defaultDashboardsTimezone: "America/New_York"
  ingress:
    enabled: true
    annotations:
      ${indent(6, var.ingress_annotations)}
    extraPaths:
      ${indent(6, var.ingress_extra_paths)}
    ingressClassName: ${var.ingress_class_name}
    hosts:
      - ${var.host_name}
EOT
}