resource "null_resource" "ingress_nginx" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/ingress-nginx-v1.8.1.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/ingress-nginx-v1.8.1.yaml"
  }
}

resource "null_resource" "arp_protocol" {
  provisioner "local-exec" {
    command = "kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e \"s/strictARP: false/strictARP: true/\" | kubectl apply -f - -n kube-system"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e \"s/strictARP: true/strictARP: false/\" | kubectl apply -f - -n kube-system"
  }
  depends_on = [null_resource.ingress_nginx]
}

resource "null_resource" "metallb" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/metallb-v0.13.10.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/metallb-v0.13.10.yaml"
  }
  depends_on = [null_resource.arp_protocol]

}

