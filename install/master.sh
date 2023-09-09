sudo modprobe br_netfilter
sudo mkdir -p /proc/sys/net/bridge
sudo echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
sudo kubeadm init

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
kubectl create secret generic kubeconfig --from-file=$HOME/.kube/config -n kube-system

mkdir -p $HOME/.ssh
ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ""
kubectl create secret generic node-private --from-file=$HOME/.ssh/id_rsa -n kube-system
kubectl create secret generic node-public --from-file=$HOME/.ssh/id_rsa.pub -n kube-system
kubectl create secret generic node-username --from-literal=username=$USER -n kube-system
