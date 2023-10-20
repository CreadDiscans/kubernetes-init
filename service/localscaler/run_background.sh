cp /etc/kubeconfig/config /root/.kube/config; 
cp /etc/node_ssh/id_rsa /root/.ssh/
chmod 400 /root/.ssh/id_rsa
echo $PROMETHEUS > /app/.env; 
sleep 60;
service uwsgi start; 
service nginx start;
/usr/bin/redis-server --daemonize yes;
/usr/local/bin/celery -A config worker -B -l info -c 1;