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
          args = [
            "start",
            "--hostname=${var.prefix}.${var.domain}",
            "--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true",
            "--db mysql",
            "--db-url jdbc:mysql://mysql-service:3306/keycloak",
            "--db-username ${local.db.user}",
            "--db-password \"${local.db.password}\""
          ]
          env {
            name  = "KEYCLOAK_ADMIN"
            value = var.admin.username
          }
          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = var.admin.password
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
  domain    = var.domain
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    app = kubernetes_deployment.keycloak_deploy.metadata.0.labels.app
  }
}
