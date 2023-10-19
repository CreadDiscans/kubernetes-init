resource "kubernetes_service_account" "runner_sa" {
  metadata {
    name      = "runner-sa"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
}

resource "kubernetes_role" "runner_role" {
  metadata {
    name      = "runner-role"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "pods/exec", "serviceaccounts", "pods/attach"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "runner_role_binding" {
  metadata {
    name      = "runner-rb"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.runner_sa.metadata.0.name
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.runner_role.metadata.0.name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_config_map" "runner_config" {
  metadata {
    name      = "runner-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "config.toml" = <<EOF
        concurrent = 4
        [[runners]]
        tls-ca-file = "/etc/gitlab-runner/certs/tls.crt"
        name = "kubernetes-runner"
        url = "https://${local.prefix}.${var.domain}"
        token = "$TOKEN"
        executor = "kubernetes"
        [runners.kubernetes]
            namespace = "${kubernetes_namespace.ns.metadata.0.name}"
            image = "docker:latest"
            privileged = true
            cpu_request = "1"
            cpu_limit = "1"
            memory_request = "4Gi"
            memory_limit = "4Gi"
            [[runners.kubernetes.volumes.host_path]]
              name = "docker"
              mount_path = "/var/run/docker.sock"
              host_path = "/var/run/docker.sock"
        EOF
  }
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "runner-pvc"
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

resource "kubernetes_deployment" "runner" {
  metadata {
    name      = "gitlab-runner"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "gitlab-runner"
      }
    }
    template {
      metadata {
        labels = {
          name = "gitlab-runner"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.runner_sa.metadata.0.name
        init_container {
          name  = "gitlab-runner-token-getter"
          image = "creaddiscans/gitlab-runner-token-getter:0.8"
          env {
            name  = "HOST"
            value = "https://${local.prefix}.${var.domain}"
          }
          env {
            name  = "USERNAME"
            value = "root"
          }
          env {
            name  = "PASSWORD"
            value = var.password
          }
          env {
            name  = "SOURCE"
            value = "/etc/gitlab-runner/config.toml"
          }
          env {
            name  = "DESTINATION"
            value = "/etc/gitlab-runner-getter/config.toml"
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/gitlab-runner/config.toml"
            read_only  = true
            sub_path   = "config.toml"
          }
          volume_mount {
            name       = "config-with-token"
            mount_path = "/etc/gitlab-runner-getter"
          }
        }
        container {
          image             = "gitlab/gitlab-runner:v16.4.1"
          image_pull_policy = "Always"
          name              = "gitlab-runner"
          resources {
            requests = {
              cpu    = "50m"
              memory = "100Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "200Mi"
            }
          }
          volume_mount {
            name       = "config-with-token"
            mount_path = "/etc/gitlab-runner/config.toml"
            read_only  = true
            sub_path   = "config.toml"
          }
          volume_mount {
            name       = "gitlab-cert"
            mount_path = "/etc/gitlab-runner/certs"
            read_only  = true
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.runner_config.metadata.0.name
          }
        }
        volume {
          name = "config-with-token"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.pvc.metadata.0.name
          }
        }
        volume {
          name = "gitlab-cert"
          secret {
            secret_name = "${local.prefix}-cert"
          }
        }
        restart_policy = "Always"
      }
    }
  }
  depends_on = [time_sleep.wait_deploy]
}
