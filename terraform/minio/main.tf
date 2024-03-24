resource "kubernetes_namespace" "ns" {
  metadata {
    name = "minio-storage"
  }
}

resource "kubernetes_persistent_volume_claim" "deploy_pvc" {
  metadata {
    name      = "minio-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "nfs-volume"
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
          command = ["/bin/sh", "-c"]
          args = [
            "sleep 5 && mc mb /storage/cnpg && mc mb /storage/airflow && minio server --console-address :9001 /storage --address :9000"
          ]
          resources {
            requests = {
              cpu    = "10m"
              memory = "2048Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "2048Mi"
            }
          }
          env {
            name  = "MINIO_ROOT_USER"
            value = var.minio_creds.username
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.minio_creds.password
          }
          env {
            name  = "TZ"
            value = "Asia/Seoul"
          }
          env {
            name  = "LANG"
            value = "ko_KR.utf8"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CONFIG_URL"
            value = "https://${var.prefix.gitlab}.${var.domain}/.well-known/openid-configuration"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_DISPLAY_NAME"
            value = "gitlab-oidc"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_SCOPES"
            value = "openid,email"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CLAIM_NAME"
            value = "groups_direct"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_REDIRECT_URI_DYNAMIC"
            value = "on"
          }
          env {
            name = "MINIO_IDENTITY_OPENID_CLIENT_ID"
            value = "${var.oidc.client_id}"
          }
          env {
            name = "MINIO_IDENTITY_OPENID_CLIENT_SECRET"
            value = "${var.oidc.client_secret}"
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
            claim_name = kubernetes_persistent_volume_claim.deploy_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.minio
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 9001
  selector = {
    app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
  }
}

resource "kubernetes_service" "gateway" {
  metadata {
    name      = "minio-gateway-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    port {
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
    }
    selector = {
      app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
    }
  }
}
