resource "kubernetes_namespace" "ns" {
  metadata {
    name = "autoscaler"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

data "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-k8s"
    namespace = "monitoring"
  }
}
data "kubernetes_secret" "kubeconfig" {
  metadata {
    name      = "kubeconfig"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "nodessh" {
  metadata {
    name      = "node-ssh"
    namespace = "kube-system"
  }
}

resource "kubernetes_secret" "kubeconfig" {
  metadata {
    name      = "kubeconfig"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = data.kubernetes_secret.kubeconfig.data
}

resource "kubernetes_secret" "nodessh" {
  metadata {
    name      = "node-ssh"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = data.kubernetes_secret.nodessh.data
}

resource "kubernetes_persistent_volume_claim" "db" {
  metadata {
    name      = "locascaler-db"
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

resource "kubernetes_deployment" "foreground" {
  metadata {
    name = "localscaler"
    labels = {
      app = "localscaler"
    }
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "localscaler"
      }
    }
    template {
      metadata {
        labels = {
          app = "localscaler"
        }
      }
      spec {
        node_name = "master"
        container {
          name    = "localscaler-background"
          image   = "creaddiscans/localscaler:0.37"
          command = ["/bin/bash", "run_foreground.sh"]
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
          volume_mount {
            name       = "db"
            mount_path = "/app/db"
          }
        }
        volume {
          name = "db"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.db.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "background" {
  metadata {
    name = "localscaler-background"
    labels = {
      app = "localscaler-background"
    }
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "localscaler-background"
      }
    }
    template {
      metadata {
        labels = {
          app = "localscaler-background"
        }
      }
      spec {
        node_name    = "master"
        host_network = true
        container {
          name    = "localscaler"
          image   = "creaddiscans/localscaler:0.37"
          command = ["/bin/bash", "run_background.sh"]
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
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
          volume_mount {
            name       = "db"
            mount_path = "/app/db"
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
        volume {
          name = "db"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.db.metadata.0.name
          }
        }
      }
    }
  }
  depends_on = [kubernetes_deployment.foreground]
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = kubernetes_deployment.foreground.metadata.0.name
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 80
  selector = {
    app = "localscaler"
  }
  gateway = true
}
