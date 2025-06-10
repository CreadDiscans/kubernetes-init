# pub key 확인

- kubectl -n ingress-nginx get secret ssh-key-secret -o jsonpath="{['data']['id_rsa\.pub']}" | base64 --decode && echo

# ssh 연결

- ~/.ssh/authorization_keys 파일에 pub 키 등록