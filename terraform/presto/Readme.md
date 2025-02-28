# DB 정보 추가

- presto-catalog configmap에 db 정보 추가
```
mysql.properties: |
    connector.name=mysql
    connection-url=jdbc:mysql://<MYSQL_URL>>:3066
    connection-user=<USERNAME>
    connection-password=<PASSWORD
```