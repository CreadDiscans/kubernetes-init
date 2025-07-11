resource "kubernetes_secret" "config" {
  metadata {
    name      = "grafana-config"
    namespace = local.namespace
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
root_url = https://${var.prefix}.${var.route.domain}
[auth]
signout_redirect_url = ${var.keycloak.url}/realms/${module.oidc.auth.realm}/protocol/openid-connect/logout
disable_login_form = true
oauth_allow_insecure_email_lookup = true
[auth.generic_oauth]
enabled = true
name = Keycloak-OAuth
allow_sign_up = true
scopes = openid email profile offline_access
client_id = '${local.client_id}'
client_secret = '${module.oidc.auth.client_secret}'
auth_url = ${var.keycloak.url}/realms/${module.oidc.auth.realm}/protocol/openid-connect/auth
token_url = ${var.keycloak.url}/realms/${module.oidc.auth.realm}/protocol/openid-connect/token
api_url = ${var.keycloak.url}/realms/${module.oidc.auth.realm}/protocol/openid-connect/userinfo
role_attribute_path: contains(groups[*], '/grafana') && 'Admin' || 'Viewer'
tls_skip_verify_insecure = true
[security]
allow_embedding = true
    EOF
  }
}

module "manifests" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml"
}

module "grafana" {
  source    = "../utils/service"
  route     = var.route
  prefix    = var.prefix
  namespace = local.namespace
  port      = 3000
  selector = {
    "app.kubernetes.io/component" = "grafana"
    "app.kubernetes.io/name"      = "grafana"
    "app.kubernetes.io/part-of" : "kube-prometheus"
  }
  annotations = {
    "sysflow/favicon" = "/public/img/grafana_icon.svg"
    "sysflow/doc"     = "https://grafana.com/docs/grafana/latest/dashboards/"
  }
  depends_on = [module.manifests]
}

module "oidc" {
  source       = "../utils/oidc"
  keycloak     = var.keycloak
  client_id    = local.client_id
  prefix       = var.prefix
  domain       = var.route.domain
  redirect_uri = ["https://${var.prefix}.${var.route.domain}/login/generic_oauth"]
}
