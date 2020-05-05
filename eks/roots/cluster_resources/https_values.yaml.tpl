nginx-ingress:
  Enabled: true
  rbac:
    create: true
  controller:
    ingressClass: "nginx"
    config:
      use-proxy-protocol: "true"
      http-snippet: |
        map '' $pass_access_scheme {
            default          https;
        }
        map '' $pass_port {
            default          443;
        }
        server {
          listen 8080 proxy_protocol;
          return 301 https://$host$request_uri;
        }
    service:
      targetPorts:
        http: 8080
        https: http
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
        service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
        service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${acm_certificate_arn}"
        service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS-1-2-2017-01"
        service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '3600'
      externalTrafficPolicy: "Local"
  tcp:
    50000: "{{ .Release.Namespace }}/cjoc:50000:PROXY"
