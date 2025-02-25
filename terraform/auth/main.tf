
resource "kubernetes_config_map" "authservice_configmap" {
  metadata {
    name      = "authservice"
    namespace = "istio-system"
  }
  data = {
    "config.json" = <<EOF
{
  "listen_address": "0.0.0.0",
  "listen_port": "10003",
  "log_level": "trace",
  "allow_unmatched_requests": false,
  "chains": [
    ${local.config_chains}
  ]
}
    EOF
  }
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name      = "authservice"
    namespace = "istio-system"
    labels = {
      app = "authservice"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "authservice"
      }
    }
    template {
      metadata {
        labels = {
          app = "authservice"
        }
      }
      spec {
        container {
          name              = "authservice"
          image             = "creaddiscans/authservice:1.0.4"
          image_pull_policy = "IfNotPresent"
          resources {
            requests = {
              cpu    = "10m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
          port {
            container_port = 10003
          }
          volume_mount {
            name       = "authservice-config"
            mount_path = "/etc/authservice"
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 10004
            }
          }
        }
        volume {
          name = "authservice-config"
          config_map {
            name = "authservice"
          }
        }
      }
    }
  }
  depends_on = [kubernetes_config_map.authservice_configmap]
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].env,
      spec[0].template[0].metadata[0].annotations
    ]
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = "authservice"
    namespace = "istio-system"
    labels = {
      app = "authservice"
    }
  }
  spec {
    port {
      name = "grpc"
      port = 10003
    }
    selector = {
      app = "authservice"
    }
  }
}

module "policy" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/policy.yaml"
}
