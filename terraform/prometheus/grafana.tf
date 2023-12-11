
resource "kubernetes_deployment" "grafana_deploy" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/component" = "grafana"
      "app.kubernetes.io/name"      = "grafana"
      "app.kubernetes.io/part-of"   = "kube-prometheus"
      "app.kubernetes.io/version"   = "9.5.3"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/component" = "grafana"
        "app.kubernetes.io/name"      = "grafana"
        "app.kubernetes.io/part-of"   = "kube-prometheus"
      }
    }
    template {
      metadata {
        annotations = {
          "checksum/grafana-config"             = "5c598ba58d9b65011bdbb3864138399a"
          "checksum/grafana-dashboardproviders" = "c9c1743868aa1c3dab60d2c402e2dcf0"
          "checksum/grafana-datasources"        = "5ef0e6acaa5b4e8603740fbad440717d"
        }
        labels = {
          "app.kubernetes.io/component" = "grafana"
          "app.kubernetes.io/name"      = "grafana"
          "app.kubernetes.io/part-of"   = "kube-prometheus"
          "app.kubernetes.io/version"   = "9.5.3"
        }
      }
      spec {
        automount_service_account_token = false
        init_container {
          name  = "gitlab-oidc"
          image = "creaddiscans/selenium_script:0.1"
          volume_mount {
            name       = "script"
            mount_path = "/app"
          }
          volume_mount {
            name       = "grafana-config"
            mount_path = "/etc/grafana-raw"
          }
          volume_mount {
            name = "grafana-config-with-oidc"
            mount_path = "/etc/grafana"
          }
          security_context {
            run_as_user = 0
          }
        }
        container {
          image = "grafana/grafana:9.5.3"
          name  = "grafana"
          port {
            container_port = 3000
            name           = "http"
          }
          readiness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }
          }
          resources {
            limits = {
              cpu    = "200m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "100Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            seccomp_profile {
              type = "RuntimeDefault"
            }
          }
          volume_mount {
            mount_path = "/var/lib/grafana"
            name       = "grafana-storage"
            read_only  = false
          }
          volume_mount {
            mount_path = "/etc/grafana/provisioning/datasources"
            name       = "grafana-datasources"
            read_only  = false
          }
          volume_mount {
            mount_path = "/etc/grafana/provisioning/dashboards"
            name       = "grafana-dashboards"
            read_only  = false
          }
          volume_mount {
            mount_path = "/tmp"
            name       = "tmp-plugins"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/alertmanager-overview"
            name       = "grafana-dashboard-alertmanager-overview"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/apiserver"
            name       = "grafana-dashboard-apiserver"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/cluster-total"
            name       = "grafana-dashboard-cluster-total"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/controller-manager"
            name       = "grafana-dashboard-controller-manager"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/grafana-overview"
            name       = "grafana-dashboard-grafana-overview"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-cluster"
            name       = "grafana-dashboard-k8s-resources-cluster"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-multicluster"
            name       = "grafana-dashboard-k8s-resources-multicluster"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-namespace"
            name       = "grafana-dashboard-k8s-resources-namespace"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-node"
            name       = "grafana-dashboard-k8s-resources-node"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-pod"
            name       = "grafana-dashboard-k8s-resources-pod"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-workload"
            name       = "grafana-dashboard-k8s-resources-workload"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/k8s-resources-workloads-namespace"
            name       = "grafana-dashboard-k8s-resources-workloads-namespace"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/kubelet"
            name       = "grafana-dashboard-kubelet"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/namespace-by-pod"
            name       = "grafana-dashboard-namespace-by-pod"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/namespace-by-workload"
            name       = "grafana-dashboard-namespace-by-workload"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/node-cluster-rsrc-use"
            name       = "grafana-dashboard-node-cluster-rsrc-use"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/node-rsrc-use"
            name       = "grafana-dashboard-node-rsrc-use"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/nodes-darwin"
            name       = "grafana-dashboard-nodes-darwin"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/nodes"
            name       = "grafana-dashboard-nodes"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/persistentvolumesusage"
            name       = "grafana-dashboard-persistentvolumesusage"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/pod-total"
            name       = "grafana-dashboard-pod-total"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/prometheus-remote-write"
            name       = "grafana-dashboard-prometheus-remote-write"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/prometheus"
            name       = "grafana-dashboard-prometheus"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/proxy"
            name       = "grafana-dashboard-proxy"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/scheduler"
            name       = "grafana-dashboard-scheduler"
            read_only  = false
          }
          volume_mount {
            mount_path = "/grafana-dashboard-definitions/0/workload-total"
            name       = "grafana-dashboard-workload-total"
            read_only  = false
          }
          volume_mount {
            mount_path = "/etc/grafana"
            name       = "grafana-config-with-oidc"
            read_only  = false
          }
        }
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        security_context {
          fs_group        = 65534
          run_as_non_root = true
          run_as_user     = 65534
        }
        service_account_name = "grafana"
        volume {
          empty_dir {

          }
          name = "grafana-storage"
        }
        volume {
          name = "grafana-datasources"
          secret {
            secret_name = "grafana-datasources"
          }
        }
        volume {
          name = "grafana-dashboards"
          config_map {
            name = "grafana-dashboards"
          }
        }
        volume {
          empty_dir {
            medium = "Memory"
          }
          name = "tmp-plugins"
        }
        volume {
          config_map {
            name = "grafana-dashboard-alertmanager-overview"
          }
          name = "grafana-dashboard-alertmanager-overview"
        }
        volume {
          config_map {
            name = "grafana-dashboard-apiserver"
          }
          name = "grafana-dashboard-apiserver"
        }
        volume {
          config_map {
            name = "grafana-dashboard-cluster-total"
          }
          name = "grafana-dashboard-cluster-total"
        }
        volume {
          config_map {
            name = "grafana-dashboard-controller-manager"
          }
          name = "grafana-dashboard-controller-manager"
        }
        volume {
          config_map {
            name = "grafana-dashboard-grafana-overview"
          }
          name = "grafana-dashboard-grafana-overview"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-cluster"
          }
          name = "grafana-dashboard-k8s-resources-cluster"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-multicluster"
          }
          name = "grafana-dashboard-k8s-resources-multicluster"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-namespace"
          }
          name = "grafana-dashboard-k8s-resources-namespace"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-node"
          }
          name = "grafana-dashboard-k8s-resources-node"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-pod"
          }
          name = "grafana-dashboard-k8s-resources-pod"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-workload"
          }
          name = "grafana-dashboard-k8s-resources-workload"
        }
        volume {
          config_map {
            name = "grafana-dashboard-k8s-resources-workloads-namespace"
          }
          name = "grafana-dashboard-k8s-resources-workloads-namespace"
        }
        volume {
          config_map {
            name = "grafana-dashboard-kubelet"
          }
          name = "grafana-dashboard-kubelet"
        }
        volume {
          config_map {
            name = "grafana-dashboard-namespace-by-pod"
          }
          name = "grafana-dashboard-namespace-by-pod"
        }
        volume {
          config_map {
            name = "grafana-dashboard-namespace-by-workload"
          }
          name = "grafana-dashboard-namespace-by-workload"
        }
        volume {
          config_map {
            name = "grafana-dashboard-node-cluster-rsrc-use"
          }
          name = "grafana-dashboard-node-cluster-rsrc-use"
        }
        volume {
          config_map {
            name = "grafana-dashboard-node-rsrc-use"
          }
          name = "grafana-dashboard-node-rsrc-use"
        }
        volume {
          config_map {
            name = "grafana-dashboard-nodes-darwin"
          }
          name = "grafana-dashboard-nodes-darwin"
        }
        volume {
          config_map {
            name = "grafana-dashboard-nodes"
          }
          name = "grafana-dashboard-nodes"
        }
        volume {
          config_map {
            name = "grafana-dashboard-persistentvolumesusage"
          }
          name = "grafana-dashboard-persistentvolumesusage"
        }
        volume {
          config_map {
            name = "grafana-dashboard-pod-total"
          }
          name = "grafana-dashboard-pod-total"
        }
        volume {
          config_map {
            name = "grafana-dashboard-prometheus-remote-write"
          }
          name = "grafana-dashboard-prometheus-remote-write"
        }
        volume {
          config_map {
            name = "grafana-dashboard-prometheus"
          }
          name = "grafana-dashboard-prometheus"
        }
        volume {
          config_map {
            name = "grafana-dashboard-proxy"
          }
          name = "grafana-dashboard-proxy"
        }
        volume {
          config_map {
            name = "grafana-dashboard-scheduler"
          }
          name = "grafana-dashboard-scheduler"
        }
        volume {
          config_map {
            name = "grafana-dashboard-workload-total"
          }
          name = "grafana-dashboard-workload-total"
        }
        volume {
          name = "grafana-config"
          secret {
            secret_name = "grafana-config"
          }
        }
        volume {
          name = "grafana-config-with-oidc"
          empty_dir {}
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.oidc_script.metadata.0.name
          }
        }
      }
    }
  }
  depends_on = [module.manifests]
}
