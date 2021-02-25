OperationsCenter:
  Platform: aws
  HostName: ${host_name}
  Protocol: ${protocol}
  ServiceType: ClusterIP

Hibernation:
  Enabled: ${hibernation_enabled}

Agents:
  Enabled: true
  SeparateNamespace:
    Enabled: true
    Create: true
