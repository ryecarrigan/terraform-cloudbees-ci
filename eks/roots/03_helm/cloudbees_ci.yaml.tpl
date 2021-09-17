Persistence:
  StorageClass: efs-sc

OperationsCenter:
  Platform: aws
  HostName: ${host_name}
  Protocol: https
  ServiceType: ClusterIP
  CasC:
    Enabled: true
  JavaOpts:
    -Dcom.cloudbees.masterprovisioning.kubernetes.KubernetesMasterProvisioning.deleteClaim=true

Hibernation:
  Enabled: ${hibernation_enabled}

Ingress:
  Class: alb
  Annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing

sda: true
