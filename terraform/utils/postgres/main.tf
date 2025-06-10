resource "kubernetes_persistent_volume_claim" "postgresql_pvc" {
  metadata {
    name      = "postgresql-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage
      }
    }
  }
}

resource "kubernetes_config_map" "config" {
  metadata {
    name      = "postgres-config"
    namespace = var.namespace
  }
  data = {
    "postgresql.auto.conf" = join("\n", [
      for key, value in var.config : "${key} = ${value}"
    ])
  }
}

resource "kubernetes_stateful_set" "postgresql" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels = {
      app = "postgresql"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }

  spec {
    service_name = "postgresql"
    replicas     = 1

    selector {
      match_labels = {
        app = "postgresql"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgresql"
        }
      }
      spec {
        init_container {
          name    = "override-config"
          image   = "busybox:latest"
          command = ["sh", "-c", "cp /tmp/postgresql.auto.conf /var/lib/postgresql/data/postgresql.auto.conf"]
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgresql"
          }
          volume_mount {
            name       = "config"
            mount_path = "/tmp/postgresql.auto.conf"
            sub_path   = "postgresql.auto.conf"
          }
        }
        container {
          name  = "postgres"
          image = "postgres:17"
          port {
            container_port = 5432
          }
          env {
            name  = "POSTGRES_USER"
            value = var.user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = local.password
          }
          env {
            name  = "POSTGRES_DB"
            value = var.name
          }
          startup_probe {
            tcp_socket {
              port = 5432
            }
            failure_threshold = 1000
            period_seconds    = 10
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgresql"
          }
        }
        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgresql_pvc.metadata.0.name
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.config.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgresql_service" {
  metadata {
    name      = "postgresql-service"
    namespace = var.namespace
  }
  spec {
    selector = kubernetes_stateful_set.postgresql.metadata.0.labels
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

