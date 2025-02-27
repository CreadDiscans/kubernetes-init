resource "kubernetes_namespace" "ns" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/instance" = "ingress-nginx"
      "app.kubernetes.io/name"     = "ingress-nginx"
    }
  }
}

resource "kubernetes_config_map" "cm" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/name"      = "ingress-nginx"
      "app.kubernetes.io/part-of"   = "ingress-nginx"
      "app.kubernetes.io/version"   = "1.12.0"
    }
  }
  data = {
    "proxy-body-size" = "100g"
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
