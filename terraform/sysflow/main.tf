resource "kubernetes_namespace" "ns" {
  metadata {
    name = "sysflow"
  }
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.domain
  redirect_uri = [
    "https://${local.prefix}.${var.domain}/keycloak/auth/callback",
    "https://${local.prefix}.${var.domain}/authservice_callback",
  ]
  post_logout_redirect_uris = [
    "*",
  ]
}

resource "random_password" "secret_key" {
  length           = 50
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "kubernetes_secret" "secret" {
  metadata {
    name      = "sysflow-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    SECRET_KEY             = random_password.secret_key.result
    HOST_URL               = "https://${local.prefix}.${var.domain}"
    KUBEFLOW_URL           = var.kubeflow_url
    GRAFANA_URL            = var.grafana.url
    GRAFANA_PATH           = var.grafana.path
    KEYCLOAK_SERVER_URL    = var.keycloak.url
    KEYCLOAK_REALM         = module.oidc.auth.realm
    KEYCLOAK_CLIENT_ID     = module.oidc.auth.client_id
    KEYCLOAK_CLIENT_SECRET = module.oidc.auth.client_secret
    KEYCLOAK_USERNAME      = var.keycloak.username
    KEYCLOAK_PASSWORD      = var.keycloak.password
    DB_ENGINE              = "django.db.backends.postgresql"
    DB_NAME                = "sysflow"
    DB_USER                = "sysflow"
    DB_PASSWORD            = random_password.db_password.result
    DB_HOST                = "postgres-service"
    DB_PORT                = "5432"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        "storage" = "1Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "postgres"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:17"
          port {
            container_port = 5432
          }
          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.secret.metadata.0.name
                key  = "DB_NAME"
              }
            }
          }
          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.secret.metadata.0.name
                key  = "DB_USER"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.secret.metadata.0.name
                key  = "DB_PASSWORD"
              }
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    port {
      port        = 5432
      target_port = 5432
    }
    selector = kubernetes_deployment.postgres.metadata.0.labels
  }
}

resource "kubernetes_service_account" "sa" {
  metadata {
    name      = "sysflow-service-account"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
}

resource "kubernetes_cluster_role" "cluster_role" {
  metadata {
    name = "sysflow-cluster-role"
  }
  rule {
    api_groups = ["kubeflow.org"]
    resources  = ["profiles"]
    verbs = [
      "create",
      "delete",
      "deletecollection",
      "get",
      "list",
      "patch",
      "update",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "bind" {
  metadata {
    name = "sysflow-cluster-role-bind"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_role.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.sa.metadata.0.name
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name      = "sysflow-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "sysflow"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "sysflow"
      }
    }
    template {
      metadata {
        labels = {
          app = "sysflow"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.sa.metadata.0.name
        container {
          name  = "sysflow"
          image = "creaddiscans/sysflow:1.0.6"
          port {
            container_port = 80
          }
          volume_mount {
            name       = "secret"
            mount_path = "/etc/secret/"
            read_only  = true
          }
        }
        container {
          name    = "operator"
          image   = "creaddiscans/sysflow:1.0.6"
          command = ["bash", "-c", "python3 manage.py operator --settings=config.prod.settings"]
          volume_mount {
            name       = "secret"
            mount_path = "/etc/secret/"
            read_only  = true
          }
        }
        volume {
          name = "secret"
          secret {
            secret_name = kubernetes_secret.secret.metadata.0.name
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  namespace = kubernetes_namespace.ns.metadata.0.name
  prefix    = local.prefix
  domain    = var.domain
  port      = 80
  selector  = kubernetes_deployment.deploy.metadata.0.labels
}
