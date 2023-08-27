# 환경

Ubuntu 22.04
kubernetes 1.27
weavenet 2.8.1 [https://github.com/weaveworks/weave]
ingress-nginx 1.8.1 [https://github.com/kubernetes/ingress-nginx]

# kubernetes install 방법

마스터 노드에서
bash setup.sh
bash master.sh

워커 노드에서
bash setup.sh
bash worker.sh MASTER_IP TOKEN DISCOVERY_TOKEN_CA_CERT_HASH