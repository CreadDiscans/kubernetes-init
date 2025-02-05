resource "kubernetes_namespace" "ns" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/instance" = "ingress-nginx"
      "app.kubernetes.io/name"     = "ingress-nginx"
    }
  }
}

module "ingress_nginx" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/ingress-nginx-v1.12.0.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "tcp_config" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/ingress-nginx-tcp.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "arp_protocol" {
  source     = "../utils/update"
  get        = "kubectl get configmap kube-proxy -n kube-system -o yaml"
  from       = "strictARP: false"
  to         = "strictARP: true"
  namespace  = "kube-system"
  depends_on = [module.ingress_nginx]
}

module "metallb" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/metallb-v0.14.9.yaml"
  depends_on = [module.arp_protocol]
}

resource "time_sleep" "wait_metallb" {
  create_duration = "120s"
  depends_on      = [module.metallb]
}

module "metallb_config" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/metallb-config.yaml"
  args = {
    external_ips = var.external_ips
  }
  depends_on = [time_sleep.wait_metallb]
}

module "set_loadbalancer" {
  source     = "../utils/update"
  get        = "kubectl get service ingress-nginx-controller -n ingress-nginx -o yaml"
  from       = "type: NodePort"
  to         = "type: LoadBalancer"
  namespace  = "ingress-nginx"
  depends_on = [module.metallb_config]
}
