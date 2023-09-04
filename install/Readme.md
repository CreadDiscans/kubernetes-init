# kubernetes install 방법

마스터 노드에서
bash setup.sh
bash fixed_ip.sh IP GATEWAY_IP
reboot
bash master.sh

워커 노드에서
bash setup.sh
bash fixed_ip.sh IP GATEWAY_IP
reboot
bash wol.sh DEVICE_NAME # ifconfig로 확인
bash worker.sh MASTER_IP TOKEN DISCOVERY_TOKEN_CA_CERT_HASH