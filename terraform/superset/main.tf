resource "kubernetes_namespace" "ns" {
  metadata {
    name = "superset"
  }
}

module "superset" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/superset.yaml"
  args = {
    secretkey     = local.secretkey
    realm         = "master"
    keycloak_url  = var.keycloak.url
    client_id     = local.client_id
    client_secret = module.oidc.auth.client_secret
    prefix        = local.prefix
    domain        = var.route.domain
  }
  depends_on = [kubernetes_namespace.ns]
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8088
  selector = {
    app     = "superset"
    release = "superset"
  }
  annotations = {
    "sysflow/favicon" = "/static/assets/images/favicon.png"
    "sysflow/doc"     = "https://superset.apache.org/docs/using-superset/creating-your-first-dashboard"
  }
  depends_on = [module.superset]
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.route.domain
  redirect_uri = [
    "http://${local.prefix}.${var.route.domain}/authorize"
  ]
}
