#!/bin/sh
if [ $# -ne 1 ]; then
    echo "Usage: $0 IP_ADDRESS"
    exit -1
fi
sudo sed -i 's/dhcp4: true/ addresses:\n        - '$1'\/24/g' /etc/netplan/00-installer-config.yaml
sudo netplan apply
