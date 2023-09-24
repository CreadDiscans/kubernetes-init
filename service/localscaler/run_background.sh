cp /etc/kubeconfig/config /root/.kube/config; 
cp /etc/node_ssh/id_rsa /root/.ssh/
chmod 400 /root/.ssh/id_rsa
echo $PROMETHEUS > /app/.env; 
service supervisor start; 
redis-server