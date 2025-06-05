# helm repo add kubeai https://www.kubeai.org
helm template kubeai kubeai/kubeai -n kubeai > yaml/kubeai.yaml