resource "kubernetes_namespace" "ns" {
  metadata {
    name = "argocd"
  }
}

module "oidc" {
  source       = "../utils/oidc"
  namespace    = kubernetes_namespace.ns.metadata.0.name
  gitlab_host  = "https://${var.prefix.gitlab}.${var.domain}"
  password     = var.password
  redirect_uri = "https://${var.prefix.argocd}.${var.domain}/auth/callback"
  name         = "argocd"
}

data "kubernetes_secret" "cert" {
  metadata {
    name      = "${var.prefix.gitlab}-cert"
    namespace = "gitlab-devops"
  }
}

data "kubernetes_secret" "oidc_secret" {
  metadata {
    name      = module.oidc.secret
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  depends_on = [module.oidc]
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
    url           = "https://${var.prefix.argocd}.${var.domain}"
    "oidc.config" = <<EOF
name: Gitlab
issuer: https://${var.prefix.gitlab}.${var.domain}
clientID: ${data.kubernetes_secret.oidc_secret.data.client_id}
clientSecret: $oidc.keycloak.clientSecret
requestedScopes: ["openid", "profile", "email"]
rootCA: |
      ${replace(data.kubernetes_secret.cert.data["tls.crt"], "\n", "\n      ")}
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
    "oidc.keycloak.clientSecret" = "${data.kubernetes_secret.oidc_secret.data.client_secret}"
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
    scopes = "[groups_direct]"
    "policy.csv" = <<EOF
g, consoleAdmin, role:admin
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
  prefix    = var.prefix.argocd
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    "app.kubernetes.io/name" = "argocd-server"
  }
  depends_on = [module.install]
}
