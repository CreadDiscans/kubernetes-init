# 구성

- Ubuntu                            24.04
- kubernetes                        1.32
- calico                            3.29.1      [https://github.com/projectcalico/calico]
- metallb                           0.14.9      [https://github.com/metallb/metallb]
- ingress-nginx                     1.12.0      [https://github.com/kubernetes/ingress-nginx]
- cert-manager                      1.17.2      [https://github.com/cert-manager/cert-manager]
- istio                             1.24.2      [https://github.com/istio/istio]
- rook                              1.15.9      [https://github.com/rook/rook]
- nfs-subdir-external-provisioner   4.0.18      [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner]
- keycloak                          26.1.0      [https://www.keycloak.org/]
- kube-prometheus                   0.14.0      [https://github.com/prometheus-operator/kube-prometheus]
- argocd                            2.13.3      [https://github.com/argoproj/argo-cd]
- minio-operator                    7.0.0       [https://github.com/minio/operator]
- gitlab-ce                         17.8.1-ce.0 [https://gitlab.com/rluna-gitlab/gitlab-ce]
- airflow                           2.10.4      [https://github.com/apache/airflow/]
- kubeflow                          1.9.1       [https://github.com/kubeflow/manifests]
- cnpg                              1.25.0      [https://github.com/cloudnative-pg/cloudnative-pg]
- milvus-operator                   1.2.0       [https://github.com/zilliztech/milvus-operator]
- spark-operator                    2.1.0       [https://github.com/kubeflow/spark-operator]
- jenkins                           5.8.10      [https://github.com/jenkinsci/helm-charts]
- authservice                       1.0.4       [https://github.com/CreadDiscans/authservice]
- presto                            0.3.0       [https://prestodb.github.io/presto-helm-charts]
- superset                          0.14.0      [https://github.com/apache/superset]
- opencost                          1.43.2      [https://github.com/opencost/opencost-helm-chart]
- sysflow                           1.3.4      

# kubernetes 설치

install 폴더 참고

# terraform 설치

https://developer.hashicorp.com/terraform/downloads

# k9s 설치

https://github.com/derailed/k9s/releases

# Post Install

[airflow/Readme.md]

# Troubleshooting

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

