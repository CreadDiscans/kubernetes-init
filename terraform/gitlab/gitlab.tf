resource "kubernetes_namespace" "ns" {
  metadata {
    name = "gitlab-devops"
  }
}

module "postgres" {
  source    = "../utils/postgres"
  user      = "gitlab"
  name      = "gitlab"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

module "redis" {
  source    = "../utils/redis"
  namespace = kubernetes_namespace.ns.metadata.0.name
  password  = false
}

resource "kubernetes_persistent_volume_claim" "deploy_pvc" {
  metadata {
    name      = "gitlab-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

resource "kubernetes_secret" "secret" {
  metadata {
    name      = "gitlab-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "GITLAB_ROOT_PASSWORD" = local.password
  }
}

resource "kubernetes_stateful_set" "gitlab_deploy" {
  metadata {
    name      = "gitlab-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "gitlab"
    }
  }
  spec {
    service_name = "gitlab"
    replicas     = 1
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
        container {
          image = "gitlab/gitlab-ce:17.8.5-ce.0"
          name  = "gitlab"
          resources {
            requests = {
              cpu    = "100m"
              memory = "4Gi"
            }
            limits = {
              cpu    = 2
              memory = "8Gi"
            }
          }
          startup_probe {
            http_get {
              path = "/users/sign_in"
              port = 80
            }
            failure_threshold = 1000
            period_seconds    = 10
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
            external_url 'https://${var.prefix.gitlab}.${var.route.domain}'
            registry_external_url 'https://${var.prefix.registry}.${var.route.domain}'
            nginx['listen_port'] = 80
            nginx['listen_https'] = false
            registry['enable'] = true
            registry_nginx['listen_port'] = '5005'
            registry_nginx['listen_https'] = false
            registry_nginx['ssl_verify_client'] = "off"
            prometheus_monitoring['enable'] = false
            postgresql['enable'] = false
            gitlab_rails['db_database'] = "${module.postgres.name}"
            gitlab_rails['db_username'] = "${module.postgres.user}"
            gitlab_rails['db_password'] = "${module.postgres.password}"
            gitlab_rails['db_host'] = "${module.postgres.host}"
            gitlab_rails['db_port'] = ${module.postgres.port}
            gitlab_rails['omniauth_block_auto_created_users'] = false
            gitlab_rails['omniauth_providers'] = [
              {
                name: "openid_connect", # do not change this parameter
                label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
                args: {
                  name: "openid_connect",
                  scope: ["openid", "profile", "email"],
                  response_type: "code",
                  issuer:  "${var.keycloak.url}/realms/${module.oidc.auth.realm}",
                  client_auth_method: "query",
                  discovery: true,
                  uid_field: "preferred_username",
                  pkce: true,
                  client_options: {
                    identifier: "${module.oidc.auth.client_id}",
                    secret: "${module.oidc.auth.client_secret}",
                    redirect_uri: "https://${var.prefix.gitlab}.${var.route.domain}/users/auth/openid_connect/callback"
                  }
                }
              }
            ]
            redis['enable'] = false
            gitlab_rails['redis_host'] = '${module.redis.host}'
            gitlab_rails['redis_port'] = ${module.redis.port}
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
  }
  timeouts {
    create = "60m"
    update = "60m"
  }
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  prefix    = var.prefix.gitlab
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 80
  selector  = kubernetes_stateful_set.gitlab_deploy.metadata.0.labels
  annotations = {
    "sysflow/favicon" = "/assets/favicon-72a2cad5025aa931d6ea56c3201d1f18e68a8cd39788c7c80d5b2b82aa5143ef.png"
    "sysflow/doc"     = "https://docs.gitlab.com/user/get_started/"
  }
}

resource "kubernetes_service" "service_ssh" {
  metadata {
    name      = "gitlab-ssh-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = kubernetes_stateful_set.gitlab_deploy.metadata.0.labels
    port {
      name        = "22-tcp"
      port        = 22
      target_port = 22
    }
    type = "NodePort"
  }
}

module "service_registry" {
  source    = "../utils/service"
  route     = var.route
  prefix    = var.prefix.registry
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 5005
  selector  = kubernetes_stateful_set.gitlab_deploy.metadata.0.labels
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = var.prefix.gitlab
  domain    = var.route.domain
  redirect_uri = [
    "https://${var.prefix.gitlab}.${var.route.domain}/users/auth/openid_connect/callback"
  ]
}
