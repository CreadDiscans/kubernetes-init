resource "kubernetes_namespace" "ns" {
  metadata {
    name = "gitlab-devops"
  }
}

data "kubernetes_secret" "db" {
  metadata {
    name      = "gitlab-db-secret"
    namespace = "cnpg-system"
  }
}

resource "kubernetes_persistent_volume_claim" "deploy_pvc" {
  metadata {
    name      = "gitlab-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "nfs-volume"
  }
}


resource "kubernetes_secret" "secret" {
  metadata {
    name = "gitlab-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "GITLAB_ROOT_PASSWORD" = local.password
  }
}

resource "kubernetes_deployment" "gitlab_deploy" {
  metadata {
    name      = "gitlab-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "gitlab"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "gitlab"
      }
    }
    template {
      metadata {
        labels = {
          app = "gitlab"
        }
      }
      spec {
        node_selector = {
          "kubernetes.io/hostname": "master"
        }
        toleration {
          effect = "NoSchedule"
          key = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
        }
        container {
          image = "gitlab/gitlab-ce:17.8.1-ce.0"
          name  = "gitlab"
          resources {
            requests = {
              cpu    = "100m"
              memory = "4Gi"
            }
            limits = {
              cpu    = 1
              memory = "8Gi"
            }
          }
          startup_probe {
            http_get {
              path = "/users/sign_in"
              port = 80
            }
            failure_threshold = 1000
            period_seconds = 10
          }
          env {
            name  = "TZ"
            value = "Asia/Seoul"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.secret.metadata.0.name
            }
          }
          env {
            name  = "GITLAB_SKIP_UNMIGRATED_DATA_CHECK"
            value = true
          }
          env {
            name  = "GITLAB_OMNIBUS_CONFIG"
            value = <<-EOF
            external_url 'https://${var.prefix.gitlab}.${var.domain}'
            registry_external_url 'https://${var.prefix.registry}.${var.domain}'
            nginx['listen_port'] = 80
            nginx['listen_https'] = false
            registry['enable'] = true
            registry_nginx['listen_port'] = '5005'
            registry_nginx['listen_https'] = false
            registry_nginx['ssl_verify_client'] = "off"
            prometheus_monitoring['enable'] = false
            postgresql['enable'] = false
            gitlab_rails['db_database'] = "gitlab"
            gitlab_rails['db_username'] = "${data.kubernetes_secret.db.data.username}"
            gitlab_rails['db_password'] = "${data.kubernetes_secret.db.data.password}"
            gitlab_rails['db_host'] = "cluster-cnpg-rw.cnpg-system"
            gitlab_rails['db_port'] = 5432
            gitlab_rails['omniauth_block_auto_created_users'] = false
            gitlab_rails['omniauth_providers'] = [
              {
                name: "openid_connect", # do not change this parameter
                label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
                args: {
                  name: "openid_connect",
                  scope: ["openid", "profile", "email"],
                  response_type: "code",
                  issuer:  "${var.keycloak.url}/realms/${local.realm}",
                  client_auth_method: "query",
                  discovery: true,
                  uid_field: "preferred_username",
                  pkce: true,
                  client_options: {
                    identifier: "${local.client_id}",
                    secret: "${local.client_secret}",
                    redirect_uri: "https://${var.prefix.gitlab}.${var.domain}/users/auth/openid_connect/callback"
                  }
                }
              }
            ]
            # redis['enable'] = false
            # gitlab_rails['redis_host'] = 'redis-sentinel-sentinel.redis'
            # gitlab_rails['redis_port'] = 26379
            EOF
          }
          volume_mount {
            mount_path = "/etc/gitlab"
            name       = "gitlab-volume"
            sub_path   = "gitlab/config"
          }
          volume_mount {
            mount_path = "/var/opt/gitlab"
            name       = "gitlab-volume"
            sub_path   = "gitlab/data"
          }
        }
        volume {
          name = "gitlab-volume"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.deploy_pvc.metadata.0.name
          }
        }
      }
    }
    progress_deadline_seconds = 6000
  }
  timeouts {
    create = "60m"
    update = "60m"
  }
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.gitlab
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 80
  selector = {
    app = "gitlab"
  }
  depends_on = [kubernetes_deployment.gitlab_deploy]
}

resource "kubernetes_service" "service_ssh" {
  metadata {
    name      = "gitlab-ssh-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = {
      app = "gitlab"
    }
    port {
      name        = "22-tcp"
      port        = 22
      target_port = 22
    }
    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.gitlab_deploy]
}

module "service_registry" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.registry
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 5005
  selector = {
    app = "gitlab"
  }
  depends_on = [kubernetes_deployment.gitlab_deploy]
}
