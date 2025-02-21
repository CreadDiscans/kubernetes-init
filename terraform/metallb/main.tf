resource "kubernetes_namespace" "ns" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

module "arp_protocol" {
  source     = "../utils/update"
  get        = "kubectl get configmap kube-proxy -n kube-system -o yaml"
  from       = "strictARP: false"
  to         = "strictARP: true"
  namespace  = "kube-system"
  depends_on = [kubernetes_namespace.ns]
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
