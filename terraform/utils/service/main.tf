resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.prefix}-service"
    namespace = var.namespace
  }
  spec {
    selector = var.selector
    port {
      port        = 80
      target_port = var.port
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "${var.prefix}-ingress"
    annotations = {
      "ingress.kubernetes.io/ssl-redirect" = "true"
      "kubernetes.io/ingress.class"        = "nginx"
      "kubernetes.io/tls-acme"             = "true"
      "cert-manager.io/cluster-issuer"     = local.clusterissuer
    }
    namespace = var.namespace
  }
  spec {
    tls {
      hosts       = ["${var.prefix}.${var.domain}"]
      secret_name = "${var.prefix}-cert"
    }
    rule {
      host = "${var.prefix}.${var.domain}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
