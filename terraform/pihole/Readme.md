# password 확인

- kubectl -n pihole get secret my-pihole-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

# dns 접근 허용

- Settings > DNS > Permit all origins > Save

# dns 설정

- Settings > Local DNS Records > dns 추가

# coredns가 pihole 보도록 설정

- kube-system에 coredns configmap 수정 > forward . PIHOLE_IP:53