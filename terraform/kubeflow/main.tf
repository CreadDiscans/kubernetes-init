resource "kubernetes_namespace" "ns" {
  metadata {
    name = "kubeflow"
    labels = {
      control-plane   = "kubeflow"
      istio-injection = "enabled"
    }
  }
}

module "pipeline_crds" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/pipeline-crds.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "pipeline" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/pipeline.yaml"
  depends_on = [module.pipeline_crds]
}

module "centraldashboard" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/centraldashboard.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "profile" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/profile.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8002
  gateway   = true
  selector = {
    "app" = "centraldashboard"
  }
  depends_on = [module.centraldashboard]
}
