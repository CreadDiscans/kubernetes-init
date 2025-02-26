resource "kubernetes_namespace" "ns" {
  metadata {
    name = "keycloak"
  }
}

resource "kubernetes_secret" "secret" {
  metadata {
    name      = "keycloak-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    password = local.password
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
          image = "quay.io/keycloak/keycloak:26.1.0"
          args = [
            "start",
            # "--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true",
          ]
          env {
            name  = "KC_HOSTNAME"
            value = "https://${local.prefix}.${var.domain}"
          }
          env {
            name  = "KC_HTTP_ENABLED"
            value = true
          }
          env {
            name  = "KC_DB"
            value = "mysql"
          }
          env {
            name  = "KC_DB_URL"
            value = "jdbc:mysql://${kubernetes_service.mysql_svc.metadata.0.name}:3306/${local.db.name}"
          }
          env {
            name = "KC_DB_USERNAME"
            value = local.db.user
          }
          env {
            name  = "KC_DB_PASSWORD"
            value = local.db.password
          }
          env {
            name  = "KC_BOOTSTRAP_ADMIN_USERNAME"
            value = local.username
          }
          env {
            name  = "KC_BOOTSTRAP_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.secret.metadata.0.name
                key  = "password"
              }
            }
          }
          env {
            name  = "KC_HEALTH_ENABLED"
            value = true
          }
          port {
            name           = "http"
            container_port = 8080
          }
          readiness_probe {
            http_get {
              path = "/health/ready"
              port = 9000
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
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = kubernetes_deployment.keycloak_deploy.metadata.0.labels
}
