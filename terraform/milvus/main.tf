resource "kubernetes_namespace" "ns" {
  metadata {
    name = "milvus-operator"
  }
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/operator.yaml"
  depends_on = [kubernetes_namespace.ns]
}

# resource "kubernetes_secret" "minio_creds" {
#   metadata {
#     name      = "minio-secret"
#     namespace = kubernetes_namespace.ns.metadata.0.name
#   }
#   data = {
#     accesskey : var.minio_creds.username
#     secretkey : var.minio_creds.password
#   }
# }

# module "milvus" {
#   source = "../utils/apply"
#   yaml   = "${path.module}/yaml/milvus.yaml"
#   args = {
#     minio_endpoint = "${replace(var.minio_creds.url, "https://", "")}:443"
#   }
#   depends_on = [module.operator, kubernetes_secret.minio_creds]
# }

resource "kubernetes_deployment" "attu_deploy" {
  metadata {
    name      = "my-attu"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "attu"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "attu"
      }
    }
    template {
      metadata {
        labels = {
          app = "attu"
          "sidecar.istio.io/inject" : "true"
        }
      }
      spec {
        toleration {
          effect   = "NoSchedule"
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
        }
        container {
          name              = "attu"
          image             = "zilliz/attu:v2.5"
          image_pull_policy = "IfNotPresent"
          port {
            name           = "attu"
            container_port = 3000
            protocol       = "TCP"
          }
          env {
            name  = "MILVUS_URL"
            value = "my-release-milvus:19530"
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  port      = 3000
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  gateway   = "milvus-gateway"
  selector = {
    "app" = "attu"
  }
  annotations = {
    "sysflow/favicon" = "https://raw.githubusercontent.com/zilliztech/attu/refs/heads/main/client/public/attu.svg"
    "sysflow/doc"     = "https://milvus.io/docs/manage_databases.md"
  }
  depends_on = [kubernetes_deployment.attu_deploy]
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.route.domain
}
