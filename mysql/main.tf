resource "helm_release" "mysql" {
  chart     = "stable/mysql"
  name      = "database"
  namespace = "mysql"

  values = [local.mysql_values]
}

locals {
  mysql_values = <<EOF
image: "mysql"
imageTag: "5.7.28"

mysqlUser: "${var.mysql_user}"
mysqlPassword: "${var.mysql_password}"
mysqlDatabase: "${var.mysql_database}"

persistence:
  enabled: true
  accessMode: "ReadWriteOnce"
  size: "${var.database_size}"
  annotations: {}

configurationFiles:
  my.cnf: |-
   [mysqld]
   init_connect='SET collation_connection = utf8_unicode_ci'
   init_connect='SET NAMES utf8'
   character-set-server=utf8
   collation-server=utf8_unicode_ci
   skip-character-set-client-handshake
   [client]
   default-character-set=utf8

initializationFiles:
  privileges.sql: |-
    GRANT ALL PRIVILEGES ON `${var.mysql_database}%`.* TO '${var.mysql_user}'@'%';
    FLUSH PRIVILEGES;

EOF
}
