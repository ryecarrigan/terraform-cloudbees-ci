ci:
  Persistence:
    StorageClass: efs-sc

  OperationsCenter:
    Platform: aws
    HostName: ${host_name}
    Protocol: ${protocol}
    ServiceType: ClusterIP

  Hibernation:
    Enabled: ${hibernation_enabled}

cd:
  ingress:
    host: ${host_name}
  dois:
    credentials:
      adminPassword: ${admin_password}
  flowCredentials:
    adminPassword: ${admin_password}
