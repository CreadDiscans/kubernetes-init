resource "kubernetes_namespace" "ns_op" {
  metadata {
    name = "minio-operator"
  }
}

module "minio" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/minio.yaml"
  depends_on = [kubernetes_namespace.ns_op]
}

resource "kubernetes_namespace" "ns_tenant" {
  metadata {
    name = "minio-tenant"
  }
}

module "tenant" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/tenant-base.yaml"
  args = {
    username      = local.username
    password      = local.password
    keycloak      = module.oidc.auth.keycloak
    client_id     = module.oidc.auth.client_id
    client_secret = module.oidc.auth.client_secret
    realm         = module.oidc.auth.realm
  }
  depends_on = [kubernetes_namespace.ns_tenant, module.minio]
}

module "service_console" {
  source    = "../utils/service"
  route     = var.route
  port      = 9090
  prefix    = var.prefix.console
  namespace = kubernetes_namespace.ns_tenant.metadata.0.name
  selector = {
    "v1.min.io/tenant" = "myminio"
  }
  depends_on = [module.tenant]
}

module "service_api" {
  source    = "../utils/service"
  route     = var.route
  port      = 9000
  prefix    = var.prefix.api
  namespace = kubernetes_namespace.ns_tenant.metadata.0.name
  selector = {
    "v1.min.io/tenant" = "myminio"
  }
  depends_on = [module.tenant]
}

module "oidc" {
  source       = "../utils/oidc"
  keycloak     = var.keycloak
  client_id    = local.client_id
  prefix       = var.prefix.console
  domain       = var.route.domain
  policy       = "consoleAdmin"
  redirect_uri = ["https://${var.prefix.console}.${var.route.domain}/oauth_callback"]
}
