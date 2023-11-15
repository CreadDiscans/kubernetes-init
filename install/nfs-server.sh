#!/bin/sh
if [ $# -ne 2 ]; then
    echo "Usage: $0 SUBNET BACKUP_URL"
    echo "example: bash nfs-server.sh 192.168.0.0/24 192.168.0.10:/volumes1/backup"
    exit -1
fi

sudo apt install nfs-kernel-server
sudo mkdir -p /mnt/nfs

sudo echo "/mnt/nfs       $1(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server.service

sudo mkdir backup
sudo mount -t $2 /mnt/backup
chmod u+x backup.sh

sudo crontab -l > mycron
echo "0 15 * * * bash $pwd/backup.sh" >> mycron
sudo crontab mycron
rm mycron
