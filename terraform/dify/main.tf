resource "kubernetes_namespace" "ns" {
  metadata {
    name = "dify"
  }
}

module "redis" {
  source    = "../utils/redis"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

module "postgres" {
  source    = "../utils/postgres"
  name      = "dify"
  user      = "dify"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

resource "random_password" "api_key" {
  special = false
  length  = 32
}

resource "random_password" "damon_key" {
  special = false
  length  = 32
}

resource "kubernetes_config_map" "cm" {
  metadata {
    name      = "dify-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    DB_HOST                        = module.postgres.host
    DB_PORT                        = module.postgres.port
    DB_USERNAME                    = module.postgres.user
    DB_PASSWORD                    = module.postgres.password
    DB_DATABASE                    = module.postgres.name
    REDIS_HOST                     = module.redis.host
    REDIS_PORT                     = module.redis.port
    REDIS_USERNAME                 = "default"
    REDIS_PASSWORD                 = module.redis.password
    CELERY_BROKER_URL              = module.redis.connection
    CONSOLE_API_URL                = "https://${var.prefix.api}.${var.route.domain}"
    CONSOLE_WEB_URL                = "https://${var.prefix.console}.${var.route.domain}"
    STORAGE_TYPE                   = "s3"
    S3_ENDPOINT                    = var.minio_creds.url
    S3_BUCKET_NAME                 = local.bucket_name
    S3_ACCESS_KEY                  = var.minio_creds.username
    S3_SECRET_KEY                  = var.minio_creds.password
    FILES_ACCESS_TIMEOUT           = 36000
    CODE_EXECUTION_CONNECT_TIMEOUT = 36000
    CODE_EXECUTION_READ_TIMEOUT    = 36000
    CODE_EXECUTION_WRITE_TIMEOUT   = 36000
    TEXT_GENERATION_TIMEOUT_MS     = 36000000
    MIGRATION_ENABLED              = "true"
    PLUGIN_DAEMON_URL              = "http://plugin-daemon-service:5002"
    DIFY_INNER_API_URL             = module.service_api.internal_url
    DIFY_INNER_API_KEY             = random_password.api_key.result
    INNER_API_KEY_FOR_PLUGIN       = random_password.api_key.result
    SERVER_KEY                     = random_password.damon_key.result
    PLUGIN_DAEMON_KEY              = random_password.damon_key.result
    PLUGIN_DAEMON_URL              = "http://plugin-daemon-service:5002"
    PLUGIN_REMOTE_INSTALLING_HOST  = "0.0.0.0"
    PLUGIN_REMOTE_INSTALLING_PORT  = "5003"
    PLUGIN_WORKING_PATH            = "/app/storage/cwd"
    APP_WEB_URL                    = "https://${var.prefix.console}.${var.route.domain}"
    APP_API_URL                    = "https://${var.prefix.api}.${var.route.domain}"
    SERVICE_API_URL                = "https://${var.prefix.api}.${var.route.domain}"
    CODE_EXECUTION_ENDPOINT        = "http://sandbox-service:8194"
    CODE_EXECUTION_API_KEY         = "dify-sandbox"
    VECTOR_STORE                   = "milvus"
  }
}

resource "kubernetes_deployment" "web" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "web"
    }
    annotations = {
      "reloader.stakater.com/auto" : "true"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "web"
      }
    }
    template {
      metadata {
        labels = {
          app = "web"
        }
      }
      spec {
        container {
          name  = "web"
          image = "langgenius/dify-web:1.2.0"
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.cm.metadata.0.name
            }
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  namespace = kubernetes_namespace.ns.metadata.0.name
  prefix    = var.prefix.console
  route     = var.route
  port      = 3000
  selector  = kubernetes_deployment.web.metadata.0.labels
  annotations = {
    "sysflow/favicon" = "/favicon.ico"
    "sysflow/doc"     = "https://docs.dify.ai/en/introduction"
  }
}
