#ingress:
#  host: ${host_name}
#  annotations:
#    kubernetes.io/ingress.class: "nginx"
#
dois:
  credentials:
    adminPassword: ${admin_password}
flowCredentials:
  adminPassword: ${admin_password}

database:
  dbName: flowdb
  dbUser: root
  dbPassword: ${admin_password}
  dbType: mysql
  dbPort: 3306
  clusterEndpoint: ${mysql_endpoint}
  mysqlConnector:
    enabled: true
#
#mariadb:
#  enabled: true
#  db:
#    user: flow
#
#nginx-ingress:
#  enabled: false
#
#sda: true
#
server:
  volumesPermissionsInitContainer:
    enabled: false
#
#storage:
#  volumes:
#    serverPlugins:
#      storageClass: efs-sc
#
#zookeeper:
#  replicaCount: 1
#
#web:
#  sharedPluginEnabled: false

nginx-ingress:
  # cd.nginx-ingress.enabled should not be set as it would install its own copy of the ingress controller
  enabled: false
ingress:
  host: ${host_name}
  annotations:
    kubernetes.io/ingress.class: "nginx"
repository:
  # cd.repository.enabled need not be set for Analytics (only used by full CD/RO)
  enabled: false
web:
  # cd.web.sharedPluginEnabled need to be set to
  # avoid the requirement for shared storage between flow-web and flow-server
  sharedPluginEnabled: false

# cd.clusteredMode need not be set for Analytics (required for full CD/RO in production)
clusteredMode: false

mariadb:
  # cd.mariadb.enabled and associated flags preconfigure the Analytics services to use in-cluster MariaDB (external RDB required for full CD/RO in production)
  enabled: false
  db:
    user: "flow"
# cd.sda activates flags in the cloudbees-flow chart to start up by default in SDA mode, work in a single namespace & ingress host with CloudBees CI, and preconfigure the location of CI operations center
sda: true
