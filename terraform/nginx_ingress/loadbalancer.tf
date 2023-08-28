locals {
  is_linux = length(regexall("/home/", lower(abspath(path.root)))) > 0
}

resource "null_resource" "ingress_nginx" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/yaml/ingress-nginx-v1.8.1.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/yaml/ingress-nginx-v1.8.1.yaml"
  }
}

resource "null_resource" "arp_protocol_linux" {
  count = local.is_linux ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e \"s/strictARP: false/strictARP: true/\" | kubectl apply -f - -n kube-system"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e \"s/strictARP: true/strictARP: false/\" | kubectl apply -f - -n kube-system"
  }
  depends_on = [null_resource.ingress_nginx]
}

resource "null_resource" "arp_protocol_window" {
  count = local.is_linux ? 0 : 1
  provisioner "local-exec" {
    command     = "kubectl get configmap kube-proxy -n kube-system -o yaml | ${"%"}{${"$"}_ -replace \"strictARP: false\", \"strictARP: true\"} | kubectl apply -f - -n kube-system"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl get configmap kube-proxy -n kube-system -o yaml | ${"%"}{${"$"}_ -replace \"strictARP: true\", \"strictARP: false\"} | kubectl apply -f - -n kube-system"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [null_resource.ingress_nginx]
}

resource "null_resource" "metallb" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/yaml/metallb-v0.13.10.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/yaml/metallb-v0.13.10.yaml"
  }
  depends_on = [null_resource.arp_protocol_window, null_resource.arp_protocol_linux]
}

resource "time_sleep" "wait-metallb" {
  create_duration = "10s"
  depends_on      = [null_resource.metallb]
}

resource "kubectl_manifest" "metallb_config-ipaddress" {
  yaml_body = templatefile("${path.module}/yaml/metallb-config-ipaddress.yaml", {
    external_ips = var.external_ips
  })
  depends_on = [time_sleep.wait-metallb]
}
resource "kubectl_manifest" "metallb_config-advertisement" {
  yaml_body  = templatefile("${path.module}/yaml/metallb-config-advertisement.yaml", {})
  depends_on = [time_sleep.wait-metallb]
}

resource "null_resource" "set_loadbalancer_linux" {
  count = local.is_linux ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{\"spec\":{\"type\":\"NodePort\"}}'"
  }
  depends_on = [kubectl_manifest.metallb_config-ipaddress]
}

resource "null_resource" "set_loadbalancer_window" {
  count = local.is_linux ? 0 : 1
  provisioner "local-exec" {
    command     = "kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{\\\"spec\\\":{\\\"type\\\":\\\"LoadBalancer\\\"}}'"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{\\\"spec\\\":{\\\"type\\\":\\\"NodePort\\\"}}'"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [kubectl_manifest.metallb_config-ipaddress]
}