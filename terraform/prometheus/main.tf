resource "kubernetes_namespace" "ns" {
  metadata {
    name = "monitoring"
  }
}

module "setup" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests-setup.yaml"
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
      "app.kubernetes.io/version"   = "9.5.3"
    }
  }
  data = {
    "grafana.ini" = <<EOF
[date_formats]
default_timezone = UTC
[server]
root_url = https://${var.prefix.grafana}.${var.domain}
[auth]
disable_login_form = true
[auth.gitlab]
enabled = true
client_id = '${var.oidc.client_id}'
client_secret = '${var.oidc.client_secret}'
auth_url = https://${var.prefix.gitlab}.${var.domain}/oauth/authorize
token_url = https://${var.prefix.gitlab}.${var.domain}/oauth/token
api_url = https://${var.prefix.gitlab}.${var.domain}/api/v4
scopes = openid email profile api
role_attribute_path: contains(groups[*], 'consoleAdmin') && 'Admin' || 'Viewer'
    EOF
  }
}

module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests.yaml"
  depends_on = [time_sleep.wait]
}

module "grafana" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.grafana
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 3000
  selector = {
    "app.kubernetes.io/component" = "grafana"
    "app.kubernetes.io/name"      = "grafana"
    "app.kubernetes.io/part-of" : "kube-prometheus"
  }
  depends_on = [kubernetes_deployment.grafana_deploy]
}
