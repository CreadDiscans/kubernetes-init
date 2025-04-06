# root password

- kubectl -n gitlab-devops get secret gitlab-secret -o jsonpath="{['data']['GITLAB_ROOT_PASSWORD']}" | base64 --decode && echo

# 토긑 만료 기한 제거

- Admin > Settings > General > Account and limit > Require expiration date 체크 해제 > Save changes

# Container Registry 업로드 인증 시간 제한 설정

- Admin > Settings > CI/CD > Container Registry > Authorization token duration (minutes) > 값 변경 후 저장

# Keycloak 연동

- 프로필 아이콘 > Edit Profile > Account > Connect Keycloak