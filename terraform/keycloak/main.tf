resource "kubernetes_namespace" "ns" {
  metadata {
    name = "keycloak-sso"
  }
}

resource "kubernetes_deployment" "keycloak_deploy" {
  metadata {
    name      = "keycloak-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "keycloak"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "keycloak"
      }
    }
    template {
      metadata {
        labels = {
          app = "keycloak"
        }
      }
      spec {
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:22.0.1"
          args  = ["start-dev"]
          env {
            name  = "KEYCLOAK_ADMIN"
            value = var.username
          }
          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = var.password
          }
          env {
            name  = "KC_PROXY"
            value = "edge"
          }
          port {
            name           = "http"
            container_port = 8080
          }
          readiness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "keycloak_service" {
  metadata {
    name      = "keycloak-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.keycloak_deploy.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "keycloak_ingress" {
  metadata {
    name = "keycloak-ingress"
    annotations = {
      "ingress.kubernetes.io/ssl-redirect" = "true"
      "kubernetes.io/ingress.class"        = "nginx"
      "kubernetes.io/tls-acme"             = "true"
      "cert-manager.io/cluster-issuer"     = local.clusterissuer
    }
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    tls {
      hosts       = ["${local.prefix}.${var.domain}"]
      secret_name = "keycloak-cert"
    }
    rule {
      host = "${local.prefix}.${var.domain}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.keycloak_service.metadata.0.name
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
