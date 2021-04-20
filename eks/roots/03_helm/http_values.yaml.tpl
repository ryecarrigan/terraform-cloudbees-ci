# Variable {acm_certificate_arn} is unused in http template
controller:
  config:
    use-proxy-protocol: "true"
  ingressClass: "nginx"
  service:
    targetPorts:
      http: "http"
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
    externalTrafficPolicy: "Local"
