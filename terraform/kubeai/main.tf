resource "kubernetes_namespace" "ns" {
  metadata {
    name = "kubeai"
  }
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = var.prefix
  domain    = var.route.domain
  redirect_uri = [
    "http://${var.prefix}.${var.route.domain}/oauth/oidc/callback",
    "https://${var.prefix}.${var.route.domain}/oauth/oidc/callback",
  ]
}

module "kubeai" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/kubeai.yaml"
  args = {
    client_id     = module.oidc.auth.client_id
    client_secret = module.oidc.auth.client_secret
    keycloak_url  = var.keycloak.url
  }
  depends_on = [kubernetes_namespace.ns]
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    "app.kubernetes.io/instance"  = "kubeai"
    "app.kubernetes.io/component" = "open-webui"
  }
  annotations = {
    "sysflow/favicon" = "https://www.kubeai.org/assets/images/favicon.png"
    "sysflow/doc"     = "https://www.kubeai.org/"
  }
  depends_on = [module.kubeai]
}
