resource "kubernetes_persistent_volume_claim" "plugin_daemon_storage" {
  metadata {
    name      = "dify-plugin-daemon"
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

resource "kubernetes_deployment" "plugin_daemon" {
  metadata {
    name      = "plugin-daemon"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "plugin-daemon"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "plugin-daemon"
      }
    }
    template {
      metadata {
        labels = {
          app = "plugin-daemon"
        }
      }
      spec {
        container {
          name  = "plugin-daemon"
          image = "langgenius/dify-plugin-daemon:0.0.7-local"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.cm.metadata.0.name
            }
          }
          env {
            name  = "FORCE_VERIFYING_SIGNATURE"
            value = false
          }
          port {
            container_port = 5002
          }
          volume_mount {
            name       = "storage"
            mount_path = "/app/storage"
          }
        }
        volume {
          name = "storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.plugin_daemon_storage.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service_plugin_daemon" {
  metadata {
    name      = "plugin-daemon-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = kubernetes_deployment.plugin_daemon.metadata.0.labels
    port {
      port        = 5002
      target_port = 5002
    }
  }
}
