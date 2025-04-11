
resource "random_password" "clickhouse_password" {
  special = false
  length  = 16
}

resource "kubernetes_persistent_volume_claim" "clickhouse_pvc" {
  metadata {
    name      = "clickhouse-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "clickhouse" {
  metadata {
    name      = "clickhouse"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "clickhouse"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "clickhouse"
      }
    }
    template {
      metadata {
        labels = {
          app = "clickhouse"
        }
      }
      spec {
        container {
          name  = "clickhouse"
          image = "clickhouse:latest"
          env {
            name  = "CLICKHOUSE_PASSWORD"
            value = random_password.clickhouse_password.result
          }
          port {
            container_port = 8123
          }
          port {
            container_port = 9000
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/clickhouse"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.clickhouse_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "clickhouse_service" {
  metadata {
    name      = "clickhouse-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = kubernetes_deployment.clickhouse.metadata.0.labels
    port {
      port        = 9000
      target_port = 9000
      name        = "migration"
    }
    port {
      port        = 8123
      target_port = 8123
      name        = "url"
    }
  }
}
