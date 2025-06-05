# ceph lvm 설정

- lvm 삭제 : sudo lvremove /dev/ubuntu-vg/lv-0
- lvm 생성 : sudo lvcreate -n ceph-lv -l 100%FREE ubuntu-vg

# ceph dashboard password

- kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

# rook ceph cleanup

- 각 노드의  /var/lib/rook 폴더도 삭제

# ceph storage class / object storage cleanup

- fs 삭제 : ceph fs ls / rm NAME --yes-i-really-mean-it
- pool 삭제 : ceph osd pool ls / delete NAME NAME --yes-i-really-really-mean-it
- crush  rule 삭제 : ceph osd crush rule ls / rm NAME

# troubleshoot

- mon이 한개씩 계속 down 되는 현상상

$ sudo vi /usr/lib/systemd/system/containerd.service
 
LimitNOFILE=1048576 # 수정
 
$ sudo systemctl daemon-reload
$ sudo systemctl restart containerd