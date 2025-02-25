resource "kubernetes_namespace" "ns" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_config_map" "config" {
  metadata {
    name      = "argocd-cm"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/name"    = "argocd-cm"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }
  data = {
    url           = "https://${local.prefix}.${var.domain}"
    "oidc.config" = <<EOF
name: Keycloak
issuer: ${var.keycloak.url}/realms/${module.oidc.auth.realm}
clientID: ${local.client_id}
clientSecret: $oidc.keycloak.clientSecret
requestedScopes: ["openid", "profile", "email"]
    EOF
  }
}

resource "kubernetes_secret" "secret" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/name"    = "argocd-secret"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }
  data = {
    "oidc.keycloak.clientSecret" = "${module.oidc.auth.client_secret}"
  }
  type = "Opaque"
}

resource "kubernetes_config_map" "rbac_config" {
  metadata {
    name      = "argocd-rbac-cm"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/name"    = "argocd-rbac-cm"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }
  data = {
    "policy.csv" = <<EOF
g, /argocd, role:admin
    EOF
  }
}

module "install" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/install.yaml"
  depends_on = [kubernetes_config_map.config]
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    "app.kubernetes.io/name" = "argocd-server"
  }
  depends_on = [module.install]
}

module "oidc" {
  source    = "../utils/oidc"
  keycloak  = var.keycloak
  client_id = local.client_id
  prefix    = local.prefix
  domain    = var.domain
  redirect_uri = [
    "https://${local.prefix}.${var.domain}/auth/callback"
  ]
}
