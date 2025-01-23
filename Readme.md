# 구성

- Ubuntu                            24.04
- kubernetes                        1.32
- calico                            3.29.1
- metallb                           0.14.9
- ingress-nginx                     1.12.0
- cert-manager                      1.16.3
- nfs-subdir-external-provisioner   4.0.18      [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner]
- istio                             1.24.2      [https://github.com/istio/istio]


gitlab-ce                           16.4.1-ce.0 [https://gitlab.com/rluna-gitlab/gitlab-ce]
keycloak                            22.0.3      [https://www.keycloak.org/]
kube-prometheus                     main        [https://github.com/prometheus-operator/kube-prometheus]
cnpg                                1.20.2      [https://github.com/cloudnative-pg/cloudnative-pg]
minio                               latest      [https://github.com/minio/minio]
argocd                              2.8.4       [https://github.com/argoproj/argo-cd]
authservice                         0.10        [https://github.com/CreadDiscans/authservice]
spark                               1.1.27      [https://github.com/GoogleCloudPlatform/spark-on-k8s-operator]
airflow                             2.7.1       [https://github.com/apache/airflow/]

# kubernetes 설치

install 폴더 참고

# terraform 설치

https://developer.hashicorp.com/terraform/downloads

# k9s 설치

https://github.com/derailed/k9s/releases

# Post Install

[airflow/Readme.md]

# Troubleshooting

/run 용량 증가 : sudo mount -t tmpfs tmpfs /run -o remount,size=10G

node-exporter CrashBackoff

    - 해당 node ssh로 접속
    - sudo vi /etc/containerd/config.toml
    - default_runtime_name = "nvidia" 를 default_runtime_name = "runc" 로 교체
    - sudo service containerd restart
    - node-exporter pod 재시작
    - default_runtime_name = "runc" 를 default_runtime_name = "nvidia" 로 교체
    - sudo service containerd restart

# nvidia auto upgrade disable

/etc/apt/apt.conf.d/50unattended-upgrades

    Unattended-Upgrade::Package-Blacklist {
        "nvidia-";
        "libnvidia-";
        ...
    }

