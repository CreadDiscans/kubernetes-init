resource "kubernetes_persistent_volume_claim" "mysql_pvc" {
  metadata {
    name      = "mysql-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"
    labels = {
      app = "mysql"
    }
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        container {
          name  = "mysql"
          image = "mysql:8.4.4"
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = local.db.password
          }
          env {
            name  = "MYSQL_DATABASE"
            value = local.db.name
          }
          env {
            name  = "MYSQL_USER"
            value = local.db.user
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = local.db.password
          }
          port {
            container_port = 3306
          }
          volume_mount {
            name       = "volume1"
            mount_path = "/var/lib/mysql"
          }
        }
        volume {
          name = "volume1"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mysql_svc" {
  metadata {
    name      = "mysql-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = kubernetes_deployment.mysql.metadata.0.labels
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}
