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
