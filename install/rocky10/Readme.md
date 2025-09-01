# 파티션 확인

- lsblk 로 / 에 충분한 용량(400G 이상 확인)
- rl-home 제거가 필요한 경우
    /home 폴더 백업
    /etc/fstab에서 /dev/mapper/rl-home 주석 처리 및 재부팅 → /home 폴더 umount 됨
    /home 폴더 복구
    sudo lvremove /dev/mapper/rl-home
    sudo lvextend -l +100%FREE /dev/mapper/rl-root
    sudo xfs_growfs  /