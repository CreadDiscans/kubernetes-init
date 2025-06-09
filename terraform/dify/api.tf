resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "api"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "api"
      }
    }

    template {
      metadata {
        labels = {
          app = "api"
        }
      }
      spec {
        container {
          name  = "api"
          image = "langgenius/dify-api:1.2.0"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.cm.metadata.0.name
            }
          }
          env {
            name  = "MODE"
            value = "api"
          }
          port {
            container_port = 5001
          }
        }
      }
    }
  }
}

module "service_api" {
  source    = "../utils/service"
  prefix    = var.prefix.api
  route     = var.route
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 5001
  selector  = kubernetes_deployment.api.metadata.0.labels
}
