resource "kubernetes_namespace" "ns" {
  metadata {
    labels = {
      "pod-security.kubernetes.io/warn": "privileged"
      "pod-security.kubernetes.io/warn-version": "latest"
    }
    name = "monitoring"
  }
}

module "setup" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/setup"
  depends_on = [kubernetes_namespace.ns]
}

resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [module.setup]
}

resource "kubernetes_secret" "config" {
  metadata {
    name      = "grafana-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/component" = "grafana"
      "app.kubernetes.io/name"      = "grafana"
      "app.kubernetes.io/part-of"   = "kube-prometheus"
      "app.kubernetes.io/version"   = "11.2.0"
    }
  }
  data = {
    "grafana.ini" = <<EOF
[date_formats]
default_timezone = UTC
[server]
root_url = https://${var.prefix}.${var.domain}
[auth]
signout_redirect_url = ${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/logout
disable_login_form = true
[auth.generic_oauth]
enabled = true
name = Keycloak-OAuth
allow_sign_up = true
scopes = openid email profile offline_access
client_id = '${local.client_id}'
client_secret = '${local.client_secret}'
auth_url = ${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/auth
token_url = ${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/token
api_url = ${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/userinfo
role_attribute_path: contains(groups[*], '/grafana') && 'Admin' || 'Viewer'
tls_skip_verify_insecure = true
    EOF
  }
}

module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests"
  depends_on = [time_sleep.wait]
}

module "grafana" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 3000
  selector = {
    "app.kubernetes.io/component" = "grafana"
    "app.kubernetes.io/name"      = "grafana"
    "app.kubernetes.io/part-of" : "kube-prometheus"
  }
  depends_on = [module.manifests]
}
