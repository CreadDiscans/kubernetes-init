resource "kubernetes_namespace" "ns" {
  metadata {
    name = "langfuse"
  }
}

module "db" {
  source    = "../utils/postgres"
  user      = "langfuse"
  name      = "langfuse"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

module "redis" {
  source    = "../utils/redis"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

module "oidc" {
  source       = "../utils/oidc"
  keycloak     = var.keycloak
  client_id    = local.client_id
  prefix       = local.prefix
  domain       = var.route.domain
  redirect_uri = ["https://${local.prefix}.${var.route.domain}/api/auth/callback/keycloak"]
}

resource "kubernetes_config_map" "langfuse_cm" {
  metadata {
    name      = "langfuse-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    NEXTAUTH_URL                               = "https://langfuse.geok8s.sys-flow.com"
    NEXTAUTH_SECRET                            = "mysecret"
    AUTH_KEYCLOAK_CLIENT_ID                    = module.oidc.auth.client_id
    AUTH_KEYCLOAK_CLIENT_SECRET                = module.oidc.auth.client_secret
    AUTH_KEYCLOAK_ISSUER                       = "${module.oidc.auth.keycloak.url}/realms/master"
    SALT                                       = "mysalt"
    DATABASE_HOST                              = module.db.host
    DATABASE_USERNAME                          = module.db.user
    DATABASE_PASSWORD                          = module.db.password
    DATABASE_NAME                              = module.db.name
    CLICKHOUSE_URL                             = "http://clickhouse-service.langfuse:8123"
    CLICKHOUSE_MIGRATION_URL                   = "clickhouse://clickhouse-service.langfuse:9000"
    CLICKHOUSE_USER                            = "default"
    CLICKHOUSE_PASSWORD                        = random_password.clickhouse_password.result
    CLICKHOUSE_CLUSTER_ENABLED                 = false
    REDIS_CONNECTION_STRING                    = module.redis.connection
    LANGFUSE_S3_EVENT_UPLOAD_BUCKET            = "langfuse"
    LANGFUSE_S3_EVENT_UPLOAD_PREFIX            = "event/"
    LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT          = "https://minio-api.geok8s.sys-flow.com"
    LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID     = "pIttKZo3S5xLOcdwapc1"
    LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY = "b2q5e7oHrciONnM8Xxk9a9O4zMYohlo0yIJN4clX"
    LANGFUSE_S3_BATCH_EXPORT_BUCKET            = "langfuse"
    LANGFUSE_S3_BATCH_EXPORT_PREFIX            = "batch/"
    LANGFUSE_S3_BATCH_EXPORT_ENDPOINT          = "https://minio-api.geok8s.sys-flow.com"
    LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID     = "pIttKZo3S5xLOcdwapc1"
    LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY = "b2q5e7oHrciONnM8Xxk9a9O4zMYohlo0yIJN4clX"
    LANGFUSE_S3_MEDIA_UPLOAD_BUCKET            = "langfuse"
    LANGFUSE_S3_MEDIA_UPLOAD_PREFIX            = "media/"
    LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT          = "https://minio-api.geok8s.sys-flow.com"
    LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID     = "pIttKZo3S5xLOcdwapc1"
    LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY = "b2q5e7oHrciONnM8Xxk9a9O4zMYohlo0yIJN4clX"
  }
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name      = "langfuse"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "langfuse"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "langfuse"
      }
    }
    template {
      metadata {
        labels = {
          app = "langfuse"
        }
      }
      spec {
        container {
          name  = "langfuse"
          image = "langfuse/langfuse:latest"
          resources {
            requests = {
              cpu    = "2"
              memory = "4Gi"
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.langfuse_cm.metadata.0.name
            }
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 3000
  selector  = kubernetes_deployment.deploy.metadata.0.labels
  annotations = {
    "sysflow/favicon" = "/favicon.ico"
    "sysflow/doc"     = "https://langfuse.com/docs"
  }
}

resource "kubernetes_deployment" "worker" {
  metadata {
    name      = "langfuse-worker"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "langfuse-worker"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "langfuse-worker"
      }
    }
    template {
      metadata {
        labels = {
          app = "langfuse-worker"
        }
      }
      spec {
        container {
          name  = "langfuse-worker"
          image = "langfuse/langfuse-worker:latest"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.langfuse_cm.metadata.0.name
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_deployment.deploy]
}
