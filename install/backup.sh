day=$(date +%Y%m%dT%H%M%d)
archive_file="backup-$day.tgz"
sudo tar -Pcf /mnt/backup/$archive_file /mnt/nfs
