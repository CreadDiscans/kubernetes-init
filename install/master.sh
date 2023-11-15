sudo modprobe br_netfilter
sudo mkdir -p /proc/sys/net/bridge
sudo echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl create secret generic kubeconfig --from-file=$HOME/.kube/config -n kube-system

# calico cni
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml

# node ssh key
mkdir -p $HOME/.ssh
ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ""
kubectl create secret generic node-ssh \
    --from-file=$HOME/.ssh/id_rsa \
    --from-file=$HOME/.ssh/id_rsa.pub \
    --from-literal=username=$USER \
    -n kube-system

# nvidia plugin
kubectl create -f nvidia-device-plugin-daemonset.yaml

# k9s
wget https://github.com/derailed/k9s/releases/download/v0.28.2/k9s_Linux_amd64.tar.gz
tar -zxvf k9s_Linux_amd64.tar.gz 
sudo mv k9s /usr/bin/k9s
rm k9s_Linux_amd64.tar.gz
rm README.md
rm LICENSE
