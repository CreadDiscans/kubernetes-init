resource "kubernetes_config_map" "sandbox_cm" {
  metadata {
    name      = "sandbox-cm"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    API_KEY        = "dify-sandbox"
    GIN_MODE       = "release"
    WORKER_TIMEOUT = "36000"
    ENABLE_NETWORK = "true"
    HTTP_PROXY     = "http://ssrf-proxy-service:3128"
    HTTPS_PROXY    = "http://ssrf-proxy-service:3128"
    SANDBOX_PORT   = "8194"
  }
}

resource "kubernetes_config_map" "sandbox_template" {
  metadata {
    name      = "sandbox-template"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "config.yaml"             = <<EOF
app:
  port: 8194
  debug: True
  key: dify-sandbox
max_workers: 4
max_requests: 50
worker_timeout: 5
python_path: /usr/local/bin/python3
enable_network: True # please make sure there is no network risk in your environment
allowed_syscalls: # please leave it empty if you have no idea how seccomp works
proxy:
  socks5: ''
  http: ''
  https: ''
    EOF
    "python-requirements.txt" = <<EOF

    EOF
  }
}

resource "kubernetes_deployment" "sandbox_deploy" {
  metadata {
    name      = "sandbox"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "sandbox"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "sandbox"
      }
    }
    template {
      metadata {
        labels = {
          app = "sandbox"
        }
      }
      spec {
        container {
          name  = "sandbox"
          image = "langgenius/dify-sandbox:0.2.11"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.sandbox_cm.metadata.0.name
            }
          }
          port {
            container_port = 8194
          }
          volume_mount {
            name       = "config"
            mount_path = "/dependencies/python-requirements.txt"
            sub_path   = "python-requirements.txt"
          }
          volume_mount {
            name       = "config"
            mount_path = "/conf/config.yaml"
            sub_path   = "config.yaml"
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.sandbox_template.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sandbox_service" {
  metadata {
    name      = "sandbox-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = kubernetes_deployment.sandbox_deploy.metadata.0.labels
    port {
      port        = 8194
      target_port = 8194
    }
  }
}
