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

resource "kubernetes_stateful_set" "postgresql" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels = {
      app = "postgresql"
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
        container {
          name  = "postgres"
          image = "postgres:15"
          
          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_USER"
            value = var.user
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = var.password
          }

          env {
            name  = "POSTGRES_DB"
            value = var.name
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

