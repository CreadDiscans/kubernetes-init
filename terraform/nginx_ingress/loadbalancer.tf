module "ingress_nginx" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/ingress-nginx-v1.8.1.yaml"
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
  yaml       = "${path.module}/yaml/metallb-v0.13.10.yaml"
  depends_on = [module.arp_protocol]
}

resource "time_sleep" "wait_metallb" {
  create_duration = "60s"
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
