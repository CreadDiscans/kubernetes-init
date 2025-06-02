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
# Docker 설치 - https://docs.docker.com/engine/install/rhel/#install-using-the-repository
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable --now docker

# containerd 설정
sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
sudo systemctl restart containerd
rm cni-plugins-linux-amd64-v1.1.1.tgz

# kubeadm 설치 - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# 1.32 버전은 rocky 9 부터 지원
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

