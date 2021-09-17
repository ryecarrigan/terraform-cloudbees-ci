auth:
  username: flow
  password: ${auth_password}
  rootPassword: ${auth_password}

primary:
  extraEnvVars:
    - name: LANG
      value: C.UTF_8

initdbScripts:
  charset.sql: |
    CREATE DATABASE flowdb CHARACTER SET utf8 COLLATE utf8_general_ci;
    CREATE DATABASE flowdb_upgrade CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT ALL PRIVILEGES ON flowdb TO 'flow'@'%';
    GRANT ALL PRIVILEGES ON flowdb_upgrade TO 'flow'@'%';
    FLUSH PRIVILEGES;
