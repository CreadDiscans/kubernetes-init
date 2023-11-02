# kubernetes install 방법

MASTER 노드에서
bash setup.sh
bash fixed_ip.sh IP GATEWAY_IP
reboot
bash master.sh

WORKER 노드에서
bash setup.sh
bash fixed_ip.sh IP GATEWAY_IP
reboot
bash wol.sh DEVICE_NAME # ifconfig로 확인
bash worker.sh MASTER_IP TOKEN DISCOVERY_TOKEN_CA_CERT_HASH
bash register.sh NODE # kubectl 가능한 환경에서

WORKER 노드 GPU 설정
bash worker_cuda.sh (자동 재부팅됨, 재부팅후 다시 실행)
node 라벨에 "kubernetes.io/gpu: cuda" 추가