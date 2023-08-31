resource "kubernetes_namespace" "ns" {
  metadata {
    name = "minio-storage"
  }
}

resource "kubernetes_persistent_volume" "minio_pv" {
  metadata {
    name = "minio-pv"
    labels = {
      name = "minio-pv"
    }
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      nfs {
        server = var.nfs_ip
        path   = var.nfs_path
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "minio_pvc" {
  metadata {
    name      = "minio-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    selector {
      match_labels = {
        name = kubernetes_persistent_volume.minio_pv.metadata.0.name
      }
    }
  }
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
            claim_name = kubernetes_persistent_volume_claim.minio_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "minio_service" {
  metadata {
    name      = "minio-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 9001
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "minio_ingress" {
  metadata {
    name = "minio-ingress"
    annotations = {
      "ingress.kubernetes.io/ssl-redirect" = "true"
      "kubernetes.io/ingress.class"        = "nginx"
      "kubernetes.io/tls-acme"             = "true"
      "cert-manager.io/cluster-issuer"     = local.clusterissuer
    }
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    tls {
      hosts       = ["${local.prefix}.${var.domain}"]
      secret_name = "minio-cert"
    }
    rule {
      host = "${local.prefix}.${var.domain}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.minio_service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
