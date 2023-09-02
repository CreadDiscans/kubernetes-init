module "setup" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/manifests-setup.yaml"
}

resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [module.setup]
}

module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests.yaml"
  depends_on = [time_sleep.wait]
}

module "grafana" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = "grafana"
  namespace = "monitoring"
  port      = 3000
  selector = {
    "app.kubernetes.io/component" = "grafana"
    "app.kubernetes.io/name"      = "grafana"
    "app.kubernetes.io/part-of" : "kube-prometheus"
  }
  depends_on = [module.manifests]
}
