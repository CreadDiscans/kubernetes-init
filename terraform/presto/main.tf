resource "kubernetes_namespace" "ns" {
  metadata {
    name = "presto"
  }
}

module "presto" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/presto.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  gateway   = "presto-gateway"
  selector = {
    "app.kubernetes.io/name" : "presto"
    "app.kubernetes.io/instance" : "presto"
    "app.kubernetes.io/component" : "coordinator"
  }
  annotations = {
    "sysflow/favicon" = "/ui/assets/favicon.ico"
    "sysflow/doc"     = "https://prestodb.io/docs/current/overview.html"
  }
  depends_on = [module.presto]
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.domain
}
