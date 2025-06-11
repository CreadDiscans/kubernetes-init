# root password

- kubectl -n gitlab-devops get secret gitlab-secret -o jsonpath="{['data']['GITLAB_ROOT_PASSWORD']}" | base64 --decode && echo

# 토긑 만료 기한 제거

- Admin > Settings > General > Account and limit > Require expiration date 체크 해제 > Save changes

# Container Registry 업로드 인증 시간 제한 설정

- Admin > Settings > CI/CD > Container Registry > Authorization token duration (minutes) > 값 변경 후 저장

# Keycloak 연동

- 프로필 아이콘 > Edit Profile > Account > Connect Keycloak

# Container Registry 내부 처리

- /etc/hosts에 registry 주소 추가
- [docker]
- 노드에서 /etc/docker/daemon.json에 {"insecure-registries": ["REGISTRY 주소"]} 추가
- sudo systemctl restart docker
- docker info로 확인
- [containerd]
- 노드에서 /etc/containerd/config.toml 편집
- [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
-   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."REGISTRY주소"] # 추가
-     endpoint = ["http://REGISTRY주소"] # 추가
- [plugins."io.containerd.grpc.v1.cri".registry.configs]
-   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."REGISTRY주소".tls] # 추가
-     insecure_skip_verify = true # 추가
- sudo systemctl restart containerd
