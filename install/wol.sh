#!/bin/sh
if [ $# -ne 1 ]; then
	echo "Usage: $0 DEVICE_NAME # check ifconfig"
	exit -1
fi

sudo ethtool -s $1 wol g

echo "[Unit]"                                   > wol.service
echo "Description=Configure Wake-up on LAN"     >> wol.service
echo ""                                         >> wol.service
echo "[Service]"                                >> wol.service
echo "Type=oneshot"                             >> wol.service
echo "ExecStart=/sbin/ethtool -s $1 wol g"      >> wol.service
echo ""                                         >> wol.service
echo "[Install]"                                >> wol.service
echo "WantedBy=basic.target"                    >> wol.service

sudo mv wol.service /etc/systemd/system/wol.service
sudo systemctl enable /etc/systemd/system/wol.service
sudo systemctl start wol.servic