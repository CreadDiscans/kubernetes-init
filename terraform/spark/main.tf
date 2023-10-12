resource "kubernetes_namespace" "ns" {
  metadata {
    name = "spark-operator"
  }
}

resource "kubernetes_namespace" "ns_apps" {
  metadata {
    name = "spark-apps"
  }
}

module "crds" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/spark-crds.yaml"
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/spark-operator.yaml"
  depends_on = [kubernetes_namespace.ns, kubernetes_namespace.ns_apps]
}

module "history" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/history-server.yaml"
  depends_on = [module.operator]
}

module "history_service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns_apps.metadata.0.name
  port      = 18080
  selector = {
    app = "spark-history-server"
  }
  depends_on = [module.history]
}

module "monitor" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/monitor.yaml"
}
