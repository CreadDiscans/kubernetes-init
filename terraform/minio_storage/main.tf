resource "kubernetes_namespace" "ns" {
  metadata {
    name = "minio-storage"
  }
}

module "volume" {
  source    = "../utils/volume"
  name      = "minio"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

resource "kubernetes_deployment" "minio_deploy" {
  metadata {
    name      = "minio-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "minio"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "minio"
      }
    }
    template {
      metadata {
        labels = {
          app = "minio"
        }
      }
      spec {
        container {
          image             = "minio/minio:latest"
          image_pull_policy = "IfNotPresent"
          name              = "minio"
          security_context {
            run_as_user = 0
          }
          args = ["server", "--console-address", ":9001", "/storage"]
          env {
            name  = "MINIO_ROOT_USER"
            value = var.username
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.password
          }
          env {
            name  = "TZ"
            value = "Asia/Seoul"
          }
          env {
            name  = "LANG"
            value = "ko_KR.utf8"
          }
          port {
            container_port = 9000
            protocol       = "TCP"
          }
          port {
            container_port = 9001
            protocol       = "TCP"
          }
          volume_mount {
            name       = "minio-volume"
            mount_path = "/storage"
            sub_path   = "minio"
          }
        }
        restart_policy = "Always"
        volume {
          name = "minio-volume"
          persistent_volume_claim {
            claim_name = module.volume.pvc_name
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = "minio"
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 9001
  selector = {
    app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
  }
}

resource "kubernetes_service" "gateway" {
  metadata {
    name = "minio-gateway-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    port {
      port = 9000
      target_port = 9000
      protocol = "TCP"
    }
    selector = {
      app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
    }
  }
}
