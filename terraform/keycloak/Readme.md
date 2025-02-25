# admin password

- kubectl -n keycloak get secret keycloak-secret -o jsonpath="{['data']['password']}" | base64 --decode && echo