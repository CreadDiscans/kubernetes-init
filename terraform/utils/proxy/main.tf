

resource "kubernetes_config_map" "proxy_config" {
  metadata {
    name      = "${var.name}-config"
    namespace = var.namespace
  }
  data = {
    "nginx.conf" = <<EOF
events {
    worker_connections 1024;
}

http {
    ${var.snippet_http}
    server {
        http2 on;
        listen 80;
        set $proxy_upstream_name "-";
        location / {
            
            ${var.snippet_location}

            port_in_redirect off;

            set $pass_access_scheme  $scheme;
            set $pass_server_port    $server_port;
            set $best_http_host      $http_host;
            set $pass_port           $pass_server_port;

            proxy_pass              ${var.destination};
            proxy_set_header Host                   $best_http_host;
            proxy_set_header                        Upgrade           $http_upgrade;
            proxy_set_header X-Real-IP              $remote_addr;
            proxy_set_header X-Forwarded-For        $remote_addr;

            proxy_set_header X-Forwarded-Host       $best_http_host;
            proxy_set_header X-Forwarded-Port       $pass_port;
            proxy_set_header X-Forwarded-Proto      $pass_access_scheme;
            proxy_set_header X-Forwarded-Scheme     $pass_access_scheme;

            proxy_set_header X-Scheme               $pass_access_scheme;
            proxy_redirect                          off;
        }
    }
}
EOF
  }
}

resource "kubernetes_deployment" "proxy_deploy" {
  metadata {
    name      = "${var.name}-deploy"
    namespace = var.namespace
    labels = {
      app = "${var.name}-deploy"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "${var.name}-deploy"
      }
    }
    template {
      metadata {
        labels = {
          app = "${var.name}-deploy"
          "sidecar.istio.io/inject" : "${var.istio}"
        }
      }
      spec {
        container {
          name  = "${var.name}-deploy"
          image = "nginx:latest"
          port {
            container_port = 80
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/nginx"
            read_only  = true
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.proxy_config.metadata.0.name
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].env,
      spec[0].template[0].metadata[0].annotations
    ]
  }
}
