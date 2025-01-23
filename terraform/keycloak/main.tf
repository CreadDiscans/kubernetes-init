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
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:26.1.0"
          args = [
            "start",
            # "--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true",
          ]
          env {
            name  = "KC_HOSTNAME"
            value = "https://${var.prefix}.${var.domain}"
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
            value = "jdbc:mysql://mysql-service:3306/keycloak"
          }
          env {
            name  = "KC_DB_USERNAME"
            value = local.db.user
          }
          env {
            name  = "KC_DB_PASSWORD"
            value = local.db.password
          }
          env {
            name  = "KC_BOOTSTRAP_ADMIN_USERNAME"
            value = var.admin.username
          }
          env {
            name  = "KC_BOOTSTRAP_ADMIN_PASSWORD"
            value = var.admin.password
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
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    app = kubernetes_deployment.keycloak_deploy.metadata.0.labels.app
  }
}
