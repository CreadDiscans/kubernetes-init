resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        "storage" = "1Gi"
      }
    }
  }
}

resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    connection = "postgresql://airflow:${local.password}@postgres-service:5432/airflow"
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "postgres"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:17"
          port {
            container_port = 5432
          }
          env {
            name  = "POSTGRES_DB"
            value = "airflow"
          }
          env {
            name  = "POSTGRES_USER"
            value = "airflow"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = local.password
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    port {
      port        = 5432
      target_port = 5432
    }
    selector = kubernetes_deployment.postgres.metadata.0.labels
  }
}
