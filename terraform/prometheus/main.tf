module "setup" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/manifests-setup.yaml"
}

resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [module.setup]
}


module "grafana_config" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/grafana-config.yaml"
  args = {
    client_id     = var.oidc.client_id
    client_secret = var.oidc.client_secret
    domain        = var.domain
    prefix        = local.prefix
  }
  depends_on = [module.setup]
}

module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests.yaml"
  depends_on = [time_sleep.wait, module.grafana_config]
}

module "grafana" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = "monitoring"
  port      = 3000
  selector = {
    "app.kubernetes.io/component" = "grafana"
    "app.kubernetes.io/name"      = "grafana"
    "app.kubernetes.io/part-of" : "kube-prometheus"
  }
  depends_on = [module.manifests]
}
