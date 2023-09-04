#!/bin/sh
if [ $# -ne 1 ]; then
    echo "Usage: $0 IP_ADDRESS"
    exit -1
fi
sudo sed -i 's/dhcp4: true/dhcp4: false\n      addresses: [192.168.1.100\/24]\n      routes:\n        - to: default\n          via: 192.168.1.1\n      nameservers:\n        addresses: [8.8.8.8, 8.8.4.4]/g' /etc/netplan/00-installer-config.yaml
sudo netplan apply
