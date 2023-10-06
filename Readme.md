# 구성

Ubuntu                              22.04
kubernetes                          1.27
weavenet                            2.8.1       [https://github.com/weaveworks/weave]
ingress-nginx                       1.8.1       [https://github.com/kubernetes/ingress-nginx]
metallb                             0.13.10     [https://github.com/metallb/metallb]
cert-manager                        1.12.3      [https://github.com/cert-manager/cert-manager]
nfs-subdir-external-provisioner     4.0.18      [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner]
gitlab-ce                           16.4.1-ce.0 [https://gitlab.com/rluna-gitlab/gitlab-ce]
keycloak                            22.0.3      [https://www.keycloak.org/]
kube-prometheus                     main        [https://github.com/prometheus-operator/kube-prometheus]
cnpg                                1.20.2      [https://github.com/cloudnative-pg/cloudnative-pg]
istio                               1.19.0      [https://github.com/istio/istio]
minio                               latest      [https://github.com/minio/minio]
argocd                              2.8.4       [https://github.com/argoproj/argo-cd]
authservice                         0.10        [https://github.com/CreadDiscans/authservice]
spark                               1.1.27      [https://github.com/GoogleCloudPlatform/spark-on-k8s-operator]
airflow                             2.7.1       [https://github.com/apache/airflow/]

# 설정

ingress/yaml/metallb-config.yaml ->  addresses 값 네트워크 환경에 맞게 조절

# kubernetes 설치

install 폴더 참고

# terraform 설치

https://developer.hashicorp.com/terraform/downloads

# k9s 설치

https://github.com/derailed/k9s/releases

# Post Install

[airflow/Readme.md]