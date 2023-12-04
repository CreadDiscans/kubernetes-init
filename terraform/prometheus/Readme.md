Gitlab > admin > applications 에서 grafana 생성

scopes : openid email profile api

Callback URL : https://grafana.${domain}/login/gitlab

client_id, client_secret를 tfvars 파일에 기입

Group 이름을 consoleAdmin으로 생성
