resource "kubernetes_namespace" "ns" {
  metadata {
    name = "spark-operator"
  }
}

resource "kubernetes_namespace" "ns_apps" {
  metadata {
    name = "spark-apps"
  }
}

module "crds" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/crds"
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/spark-operator.yaml"
  depends_on = [kubernetes_namespace.ns, kubernetes_namespace.ns_apps]
}

module "history" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/history-server.yaml"
  depends_on = [module.operator]
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns_apps.metadata.0.name
  port      = 18080
  gateway   = "spark-gateway"
  selector = {
    app = "spark-history-server"
  }
  annotations = {
    "sysflow/favicon" = "/static/spark-logo-77x50px-hd.png"
    "sysflow/doc"     = "https://spark.apache.org/docs/3.5.4/api/python/getting_started/index.html"
  }
  depends_on = [module.history]
}

module "monitor" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/monitor.yaml"
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.route.domain
}
