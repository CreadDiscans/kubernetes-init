resource "kubernetes_deployment" "worker" {
  metadata {
    name      = "worker"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "worker"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "worker"
        }
      }
      spec {
        container {
          name  = "worker"
          image = "langgenius/dify-api:1.2.0"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.cm.metadata.0.name
            }
          }
          env {
            name  = "MODE"
            value = "worker"
          }
        }
      }
    }
  }
}
