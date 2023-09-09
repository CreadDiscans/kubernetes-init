data "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-k8s"
    namespace = "monitoring"
  }
}

resource "kubernetes_deployment" "localscaler" {
  metadata {
    name = "localscaler"
    labels = {
      "app.kubernetes.io/name" = "localscaler"
    }
    namespace = "kube-system"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "localscaler"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "localscaler"
        }
      }
      spec {
        host_network = true
        node_name    = "master"
        container {
          name  = "localscaler"
          image = "creaddiscans/localscaler:0.21"
          env {
            name  = "PROMETHEUS"
            value = data.kubernetes_service.prometheus.spec.0.cluster_ip
          }
          volume_mount {
            name       = "kubeconfig"
            mount_path = "/etc/kubeconfig"
            read_only  = true
          }
          volume_mount {
            name       = "node-ssh"
            mount_path = "/etc/node_ssh"
            read_only  = true
          }
        }
        volume {
          name = "kubeconfig"
          secret {
            secret_name = "kubeconfig"
          }
        }
        volume {
          name = "node-ssh"
          secret {
            secret_name = "node-ssh"
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = "localscaler"
  namespace = "kube-system"
  port      = 80
  selector = {
    "app.kubernetes.io/name" = "localscaler"
  }
}
