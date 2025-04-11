resource "kubernetes_persistent_volume_claim" "redis_pvc" {
  metadata {
    name      = "redis-pvc"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.storage
      }
    }
  }
}

resource "random_password" "password" {
  special = false
  length  = 16
}

resource "kubernetes_deployment" "redis_deploy" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels = {
      app = "redis"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis"
        }
      }
      spec {
        container {
          image = "redis:7.4.2"
          name  = "redis"
          dynamic "env" {
            for_each = var.password ? [1] : []
            content {
              name  = "REDIS_PASSWORD"
              value = random_password.password.result
            }
          }
          port {
            container_port = 6379
          }
          startup_probe {
            tcp_socket {
              port = 6379
            }
            failure_threshold = 10000
            period_seconds    = 10
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis_service" {
  metadata {
    name      = "redis-service"
    namespace = var.namespace
  }
  spec {
    selector = kubernetes_deployment.redis_deploy.metadata.0.labels
    port {
      port        = 6379
      target_port = 6379
    }
  }
}
