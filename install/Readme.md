# kubernetes install 방법

MASTER 노드에서
bash setup.sh
bash fixed_ip.sh IP GATEWAY_IP (IP 설정되어 있으면 skip)
reboot
bash master.sh

WORKER 노드에서
bash setup.sh
bash fixed_ip.sh IP GATEWAY_IP (IP 설정되어 있으면 skip)
reboot
bash net_wol.sh DEVICE_NAME # ifconfig로 확인
bash worker.sh MASTER_IP TOKEN DISCOVERY_TOKEN_CA_CERT_HASH
bash register.sh NODE # kubectl 가능한 환경에서 (node ssh가 필요한 경우)

WORKER 노드 GPU 설정
bash gpu_cuda.sh (자동 재부팅됨, 재부팅후 다시 실행)

## secret 암호화

1. key 생성 
head -c 32 /dev/urandom | base64

2. vim /etc/kubernetes/pki/secrets.yaml

kind: EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
resources:
   - resources:
     - secrets
     providers:
     - secretbox:
         keys:
         - name: key1
           secret: <KEY>
     - identity: {}

3. vim /etc/kubernetes/manifests/kube-apiserver.yaml

spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=169.56.70.197
    - --encryption-provider-config=/etc/kubernetes/pki/secrets.yaml <-- 이 부분 추가
    - --allow-privileged=true
    ...

4. pod들이 자동으로 재시작 되는것 확인

5. 기존 시크릿 데이터 암호화하여 etcd에 저장

kubectl get secrets -A -o json | kubectl replace -f -

## 네트워크 인터페이스 커스커마이징

- ifconfig에서 interface확인
- installation에서 수정
nodeAddressAutodetectionV4:
  Interface: INTERFACE

## MTU 설정

- ip a 로 mtu 확인
- mtu - 50으로 설정
- kubectl patch installation.operator.tigera.io default --type merge -p '{"spec":{"calicoNetwork":{"mtu":1450}}}'