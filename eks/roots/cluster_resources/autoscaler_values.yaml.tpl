rbac:
  create: true

cloudProvider: aws
awsRegion: ${aws_region}

image:
  repository: ${image_repository}
  tag: ${image_tag}

autoDiscovery:
  clusterName: ${cluster_name}
  enabled: true
