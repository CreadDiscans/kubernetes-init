resource "kubernetes_namespace" "ns" {
  metadata {
    name = "opencost"
  }
}

module "opencost" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/opencost.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 9090
  gateway   = "opencost-gateway"
  selector = {
    "app.kubernetes.io/instance" = "opencost"
    "app.kubernetes.io/name"     = "opencost"
  }
  annotations = {
    "sysflow/favicon" = "/favicon.7eff484d.ico"
    "sysflow/doc"     = "https://opencost.io/docs/"
  }
  depends_on = [module.opencost]
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.domain
}
