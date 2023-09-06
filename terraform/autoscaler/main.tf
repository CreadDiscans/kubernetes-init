resource "kubernetes_namespace" "ns" {
  metadata {
    name = "autoscaler"
  }
}

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
    namespace = kubernetes_namespace.ns.metadata.0.name
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
          image = "creaddiscans/localscaler:0.9"
          env {
            name  = "PROMETHEUS"
            value = data.kubernetes_service.prometheus.spec.0.cluster_ip
          }
        }
      }
    }
  }
}
