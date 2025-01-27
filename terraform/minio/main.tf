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
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              preference {
                match_expressions {
                  key      = "node-role.kubernetes.io/control-plane"
                  operator = "Exists"
                }
              }
            }
          }
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_labels = {
                  app = "minio"
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }
        toleration {
          effect   = "NoSchedule"
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
        }
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
              memory = "2Gi"
            }
            limits = {
              cpu    = "1"
              memory = "4Gi"
            }
          }
          env {
            name  = "MINIO_ROOT_USER"
            value = local.username
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = local.password
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
            value = "${var.keycloak.url}/realms/${local.realm}/.well-known/openid-configuration"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CLIENT_ID"
            value = local.client_id
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CLIENT_SECRET"
            value = local.client_secret
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_DISPLAY_NAME"
            value = "keycloak"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_SCOPES"
            value = "openid,email"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CLAIM_NAME"
            value = "policy"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_REDIRECT_URI_DYNAMIC"
            value = "on"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_VENDOR"
            value = "keycloak"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_KEYCLOAK_ADMIN_URL"
            value = "${var.keycloak.url}/admin"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_KEYCLOAK_REALM"
            value = local.realm
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

module "web_service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 9001
  selector = {
    app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
  }
}

module "api_service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = "${var.prefix}-api"
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 9000
  selector = {
    app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
  }
}
