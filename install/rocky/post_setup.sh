
# istio-init 실패 이슈 대응 - https://stackoverflow.com/questions/73473680/service-deployed-with-istio-doesnt-start-minikube-docker-mac-m1

cat <<EOT >> /etc/modules-load.d/k8s.conf
overlay
br_netfilter
nf_nat
xt_REDIRECT
xt_owner
iptable_nat
iptable_mangle
iptable_filter
EOT

modprobe br_netfilter ; modprobe nf_nat ; modprobe xt_REDIRECT ; modprobe xt_owner; modprobe iptable_nat; modprobe iptable_mangle; modprobe iptable_filter