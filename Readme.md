# 구성

Ubuntu                              22.04
kubernetes                          1.27
weavenet                            2.8.1       [https://github.com/weaveworks/weave]
ingress-nginx                       1.8.1       [https://github.com/kubernetes/ingress-nginx]
metallb                             0.13.10     [https://github.com/metallb/metallb]
cert-manager                        1.12.3      [https://github.com/cert-manager/cert-manager]
nfs-subdir-external-provisioner     4.0.18      [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner]
gitlab-ce                           16.3.0-ce.0 [https://gitlab.com/rluna-gitlab/gitlab-ce]
keycloak                            22.0.1      [https://www.keycloak.org/]

# 설정

ingress/yaml/metallb-config.yaml ->  addresses 값 네트워크 환경에 맞게 조절

# kubernetes 설치

install 폴더 참고

# terraform 설치

https://developer.hashicorp.com/terraform/downloads

# k9s 설치

https://github.com/derailed/k9s/releases