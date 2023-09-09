node=$1
if [ "$node" = "" ]; then
    echo "Node name must be specified."
    exit -1
fi

ns=kube-system
pod=$(
    kubectl create -n $ns -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  generateName: register-node-
  labels:
    plugin: register-node
spec:
  nodeName: $node
  containers:
  - name: register-node
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ['sh', '-c']
    args:
    - |
      USERNAME=\$(cat /etc/ssh/username);
      PUBKEY=\$(cat /etc/ssh/id_rsa.pub);
      mkdir -p /host/home/\$USERNAME/.ssh;
      echo \$PUBKEY >> /host/home/\$USERNAME/.ssh/authorized_keys;
    tty: true
    stdin: true
    stdinOnce: true
    securityContext:
      privileged: true
    volumeMounts:
    - name: host
      mountPath: /host
    - name: node-ssh
      mountPath: /etc/ssh
  volumes:
  - name: host
    hostPath:
      path: /
  - name: node-ssh
    secret:
        secretName: node-ssh
  hostNetwork: true
  hostIPC: true
  hostPID: true
  restartPolicy: Never
EOF
)

while :
do
    result=$(kubectl delete pod --field-selector=status.phase==Succeeded -n $ns -l plugin=register-node)
    if [ "$result" == 'No resources found' ]; then
        sleep 3
    else
        break
    fi
done