#!/bin/sh
if [ $# -ne 2 ]; then
    echo "Usage: $0 IP_ADDRESS GATEWAY_IP" 
    exit -1
fi
sudo sed -i 's/dhcp4: true/dhcp4: false\n      addresses: ['$1'\/24]\n      routes:\n        - to: default\n          via: '$2'\n      nameservers:\n        addresses: [8.8.8.8, 8.8.4.4]/g' /etc/netplan/50-cloud-init.yaml
sudo netplan apply
