resource "kubernetes_namespace" "ns" {
  metadata {
    name = "keycloak"
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
          image = "quay.io/keycloak/keycloak:22.0.3"
          args  = ["start", "--hostname=keycloak.${var.domain}", "--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true"]
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

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = "keycloak"
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    app = "keycloak"
  }
}
