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
        container {
          name  = "localscaler"
          image = "creaddiscans/localscaler:0.11"
          env {
            name  = "PROMETHEUS"
            value = data.kubernetes_service.prometheus.spec.0.cluster_ip
          }
          volume_mount {
            name       = "kubeconfig"
            mount_path = "/etc/kubeconfig"
            read_only  = true
          }
        }
        volume {
          name = "kubeconfig"
          secret {
            secret_name = "kubeconfig"
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
