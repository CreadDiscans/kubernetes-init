resource "kubernetes_namespace" "ns" {
  metadata {
    name = "mysql"
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_persistent_volume_claim" "pvc" {
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
        test = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          test = "mysql"
        }
      }
      spec {
        container {
          name  = "mysql"
          image = "mysql:8.0.26"
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = random_password.password.result
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
            claim_name = kubernetes_persistent_volume_claim.pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "svc" {
  metadata {
    name = "mysql-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = {
      app = "mysql"
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}