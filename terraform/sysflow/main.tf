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
  domain    = var.route.domain
  redirect_uri = [
    "https://${local.prefix}.${var.route.domain}/keycloak/auth/callback",
  ]
  post_logout_redirect_uris = [
    "*",
  ]
}

module "postgres" {
  source    = "../utils/postgres"
  name      = "sysflow"
  user      = "sysflow"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

resource "random_password" "secret_key" {
  length           = 50
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
    HOST_URL               = "https://${local.prefix}.${var.route.domain}"
    KUBEFLOW_URL           = var.kubeflow_url
    GRAFANA_URL            = var.grafana.url
    GRAFANA_PATH           = var.grafana.path
    KEYCLOAK_SERVER_URL    = var.keycloak.url
    KEYCLOAK_REALM         = module.oidc.auth.realm
    KEYCLOAK_CLIENT_ID     = module.oidc.auth.client_id
    KEYCLOAK_CLIENT_SECRET = module.oidc.auth.client_secret
    KEYCLOAK_USERNAME      = var.keycloak.username
    KEYCLOAK_PASSWORD      = var.keycloak.password
    DEFAULT_QUOTA_CPU      = "1"
    DEFAULT_QUOTA_MEMORY   = "8Gi"
    DEFAULT_QUOTA_GPU      = "0"
    DEFAULT_QUOTA_STORAGE  = "100Gi"
    DB_NAME                = module.postgres.name
    DB_USER                = module.postgres.user
    DB_PASSWORD            = module.postgres.password
    DB_HOST                = module.postgres.host
    DB_PORT                = module.postgres.port
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
  rule {
    api_groups = [""]
    resources  = ["limitranges"]
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
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs = [
      "get",
      "list",
      "watch"
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

resource "kubernetes_persistent_volume_claim" "sysflow_pvc" {
  metadata {
    name      = "sysflow-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name      = "sysflow-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "sysflow"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
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
          image = "creaddiscans/sysflow:1.3.4"
          port {
            container_port = 80
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.secret.metadata.0.name
            }
          }
          volume_mount {
            name       = "media"
            mount_path = "/app/media"
          }
        }
        container {
          name    = "operator"
          image   = "creaddiscans/sysflow:1.3.4"
          command = ["bash", "-c", "python3 manage.py operator --settings=config.prod.settings"]
          env_from {
            secret_ref {
              name = kubernetes_secret.secret.metadata.0.name
            }
          }
        }
        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.sysflow_pvc.metadata.0.name
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
  route     = var.route
  port      = 80
  selector  = kubernetes_deployment.deploy.metadata.0.labels
}
