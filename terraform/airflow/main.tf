resource "kubernetes_namespace" "ns" {
  metadata {
    name = "airflow"
  }
}

module "config" {
  count  = var.git_repo == "" ? 0 : 1
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/config.yaml"
  args = {
    git_repo = var.git_repo
  }
}

module "airflow" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/airflow.yaml"
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    tier      = "airflow"
    component = "webserver"
    release   = "airflow"
  }
  depends_on = [module.airflow]
}
