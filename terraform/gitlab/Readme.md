# root password

- kubectl -n gitlab-devops get secret gitlab-secret -o jsonpath="{['data']['GITLAB_ROOT_PASSWORD']}" | base64 --decode && echo