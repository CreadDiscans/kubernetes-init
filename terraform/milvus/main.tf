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

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name = "minio-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    accesskey: var.minio_creds.username
    secretkey: var.minio_creds.password
  }
}

module "milvus" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/milvus.yaml"
  args = {
    minio_endpoint = replace(var.minio_creds.url, "http://", "")
  }
  depends_on = [module.operator, kubernetes_secret.minio_creds]
}

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
        }
      }
      spec {
        node_selector = {
          "kubernetes.io/hostname": "master"
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
  depends_on = [module.milvus]
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  port      = 3000
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  selector = {
    "app" = "attu"
  }
  depends_on = [kubernetes_deployment.attu_deploy]
}
