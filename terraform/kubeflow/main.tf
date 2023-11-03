resource "kubernetes_namespace" "ns" {
  metadata {
    name = "kubeflow"
    labels = {
      control-plane   = "kubeflow"
      istio-injection = "enabled"
    }
  }
}

module "role" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/role.yaml"
  depends_on = [kubernetes_namespace.ns]
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

module "istio_resource" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/istio-resource.yaml"
  depends_on = [module.pipeline_crds]
}

module "notebook" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/notebook.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "notebook_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/notebook-web.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "admission_webhook" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/admission-webook.yaml"
  depends_on = [kubernetes_namespace.ns]
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

module "tensorboard" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/tensorboard.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "tensorboard_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/tensorboard-web.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "pvc_viewer" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/pvc-viewer.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "volume_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/volume-web.yaml"
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
