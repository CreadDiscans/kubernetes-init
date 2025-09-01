KUBERNETES_VERSION=v1.33
CRIO_VERSION=v1.33

# 방화벽 off
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# swap off
sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab

# 파일열기 갯수 제한 상향
cat <<EOF | sudo tee -a /etc/sysctl.conf
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
sudo sysctl --system

sudo dnf remove podman runc -y
# Rocky10부터 docker, containerd 미지원

# cri-o, kubeadm 설치
# https://cri-o.io/
cat <<EOF | sudo tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
EOF

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF

sudo dnf install -y container-selinux
sudo dnf install -y cri-o kubelet kubeadm kubectl
sudo systemctl start crio.service

sudo modprobe br_netfilter
sudo sysctl -w net.ipv4.ip_forward=1