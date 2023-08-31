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
    resources  = ["pods", "services", "secrets", "pods/exec", "serviceaccounts"]
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
            image = "ubuntu:22.04"
            privileged = true
        EOF
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
          image = "creaddiscans/gitlab-runner-token-getter:0.3"
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
          args              = ["run"]
          image             = "gitlab/gitlab-runner:v16.3.0"
          image_pull_policy = "Always"
          name              = "gitlab-runner"
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
          empty_dir {}
        }
        volume {
          name = "gitlab-cert"
          secret {
            secret_name = "gitlab-cert"
          }
        }
        restart_policy = "Always"
      }
    }
  }
}
