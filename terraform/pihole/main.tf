resource "kubernetes_namespace" "ns" {
  metadata {
    name = "pihole"
  }
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "secret" {
  metadata {
    name      = "my-pihole-password"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app      = "pihole"
      chart    = "pihole-2.29.1"
      heritage = "Helm"
      release  = "my-pihole"
    }
  }
  data = {
    password = random_password.password.result
  }
}

resource "kubernetes_config_map" "cm" {
  metadata {
    name      = "my-pihole-custom-dnsmasq"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "02-custom.conf"              = <<EOF
addn-hosts=/etc/addn-hosts
except-interface=nonexisting
EOF
    "addn-hosts"                  = <<EOF
EOF
    "05-pihole-custom-cname.conf" = ""
  }
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "pihole-volume"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}


resource "kubernetes_deployment" "deploy" {
  metadata {
    name      = "pihole-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "pihole"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "pihole"
      }
    }
    template {
      metadata {
        labels = {
          app = "pihole"
        }
      }
      spec {
        container {
          name  = "pihole"
          image = "pihole/pihole:latest"
          env {
            name = "FTLCONF_webserver_api_password"
            value_from {
              secret_key_ref {
                key  = "password"
                name = kubernetes_secret.secret.metadata.0.name
              }
            }
          }
          env {
            name  = "FTLCONF_webserver_port"
            value = "80"
          }
          env {
            name  = "FTLCONF_misc_etc_dnsmasq_d"
            value = "true"
          }
          port {
            container_port = 80
            name           = "http"
            protocol       = "TCP"
          }
          port {
            container_port = 53
            name           = "dns"
            protocol       = "TCP"
          }
          port {
            container_port = 53
            name           = "dns-udp"
            protocol       = "UDP"
          }
          port {
            container_port = 443
            name           = "https"
            protocol       = "TCP"
          }
          port {
            container_port = 67
            name           = "client-udp"
            protocol       = "UDP"
          }
          volume_mount {
            mount_path = "/etc/pihole"
            name       = "config"
          }
          volume_mount {
            mount_path = "/etc/dnsmasq.d/02-custom.conf"
            sub_path   = "02-custom.conf"
            name       = "custom"
          }
          volume_mount {
            mount_path = "/etc/addn-hosts"
            sub_path   = "addn-hosts"
            name       = "custom"
          }
        }
        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.pvc.metadata.0.name
          }
        }
        volume {
          name = "custom"
          config_map {
            name = kubernetes_config_map.cm.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = "pihole-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
    selector                = kubernetes_deployment.deploy.metadata.0.labels
    port {
      port        = 53
      target_port = "dns"
      protocol    = "TCP"
      name        = "dns"
    }
    port {
      port        = 53
      target_port = 53
      protocol    = "UDP"
      name        = "dns-udp"
    }
    port {
      port        = 67
      target_port = 67
      protocol    = "UDP"
      name        = "client-udp"
    }
    port {
      port        = 80
      target_port = "http"
      protocol    = "TCP"
      name        = "http"
    }
  }
  lifecycle {
    ignore_changes = [metadata.0.annotations]
  }
}
