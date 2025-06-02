# 예: /dev/sdX 를 초기화
mkfs.ext4 /dev/$1
sgdisk --zap-all /dev/$1          # GPT/MBR 파티션 테이블 삭제
dd if=/dev/zero of=/dev/$1 bs=1M count=10000
wipefs -a /dev/$1                 # 파일 시스템 시그니처 제거