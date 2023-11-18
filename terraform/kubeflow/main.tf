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

module "knative_serving" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/knative-serving.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "knative_gateway" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/knative-gateway.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "kserve" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/kserve.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "kserve_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/kserve-web.yaml"
  depends_on = [module.kserve]
}

module "katib" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/katib.yaml"
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

module "training_operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/training-operator.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "user" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/user.yaml"
  args = {
    domain = var.domain
  }
  depends_on = [module.profile]
}

resource "time_sleep" "wait" {
  create_duration = "200s"
  depends_on      = [module.user]
}


data "kubernetes_secret" "minio" {
  metadata {
    name      = "minio-creds"
    namespace = "minio-storage"
  }
}

module "user_policy" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/user-policy.yaml"
  args = {
    username = data.kubernetes_secret.minio.data.username
    password = data.kubernetes_secret.minio.data.password
  }
  depends_on = [time_sleep.wait]
}
