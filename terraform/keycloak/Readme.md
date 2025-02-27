# admin password

- kubectl -n keycloak get secret keycloak-secret -o jsonpath="{['data']['password']}" | base64 --decode && echo

# CSP 설정

- Realm settings > Security defenses > CSP > frame-src 'self'; frame-ancestors 'self' https://YOUR_URL; object-src 'none';