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

resource "random_password" "salt" {
  special = false
  length  = 16
}

resource "random_password" "secret" {
  special = false
  length  = 16
}


resource "kubernetes_config_map" "langfuse_cm" {
  metadata {
    name      = "langfuse-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    NEXTAUTH_URL                               = "https://${local.prefix}.${var.route.domain}"
    NEXTAUTH_SECRET                            = random_password.secret.result
    AUTH_KEYCLOAK_CLIENT_ID                    = module.oidc.auth.client_id
    AUTH_KEYCLOAK_CLIENT_SECRET                = module.oidc.auth.client_secret
    AUTH_KEYCLOAK_ISSUER                       = "${module.oidc.auth.keycloak.url}/realms/master"
    SALT                                       = random_password.salt.result
    DATABASE_HOST                              = module.db.host
    DATABASE_USERNAME                          = module.db.user
    DATABASE_PASSWORD                          = module.db.password
    DATABASE_NAME                              = module.db.name
    CLICKHOUSE_URL                             = "http://${kubernetes_service.clickhouse_service.metadata.0.name}:8123"
    CLICKHOUSE_MIGRATION_URL                   = "clickhouse://${kubernetes_service.clickhouse_service.metadata.0.name}:9000"
    CLICKHOUSE_USER                            = "default"
    CLICKHOUSE_PASSWORD                        = random_password.clickhouse_password.result
    CLICKHOUSE_CLUSTER_ENABLED                 = false
    REDIS_CONNECTION_STRING                    = module.redis.connection
    LANGFUSE_S3_EVENT_UPLOAD_BUCKET            = "langfuse"
    LANGFUSE_S3_EVENT_UPLOAD_PREFIX            = "event/"
    LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE  = true
    LANGFUSE_S3_EVENT_UPLOAD_REGION            = "ap-northeast-2"
    LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT          = var.minio_creds.url
    LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID     = var.minio_creds.username
    LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY = var.minio_creds.password
    LANGFUSE_S3_BATCH_EXPORT_BUCKET            = "langfuse"
    LANGFUSE_S3_BATCH_EXPORT_PREFIX            = "batch/"
    LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE  = true
    LANGFUSE_S3_BATCH_EXPORT_REGION            = "ap-northeast-2"
    LANGFUSE_S3_BATCH_EXPORT_ENDPOINT          = var.minio_creds.url
    LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID     = var.minio_creds.username
    LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY = var.minio_creds.password
    LANGFUSE_S3_MEDIA_UPLOAD_BUCKET            = "langfuse"
    LANGFUSE_S3_MEDIA_UPLOAD_PREFIX            = "media/"
    LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE  = true
    LANGFUSE_S3_MEDIA_UPLOAD_REGION            = "ap-northeast-2"
    LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT          = var.minio_creds.url
    LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID     = var.minio_creds.username
    LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY = var.minio_creds.password
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
