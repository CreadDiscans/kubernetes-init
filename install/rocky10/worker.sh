#!/bin/sh
if [ $# -ne 3 ]; then
    echo "Usage: $0 MASTER_IP TOKEN DISCOVERY_TOKEN_CA_CERT_HASH"
    echo "to check token, run following in master node"
    echo "kubeadm token list"
    echo ""
    echo "to check discovery-token-ca-cert-hash, run following in master node"
    echo "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
    exit -1
fi

sudo kubeadm join $1:6443 --token $2 --discovery-token-ca-cert-hash sha256:$3