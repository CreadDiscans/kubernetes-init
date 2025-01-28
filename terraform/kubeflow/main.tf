resource "kubernetes_namespace" "ns" {
  metadata {
    name = "kubeflow"
    labels = {
      control-plane   = "kubeflow"
      istio-injection = "enabled"
    }
  }
}

module "knative_serving_crds" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/knative-serving-crds.yaml"
}

module "knative_serving" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/knative-serving.yaml"
  depends_on = [module.knative_serving_crds]
}

module "knative_gateway" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/knative-gateway.yaml"
  depends_on = [module.knative_serving]
}

module "networkpolicy" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/networkpolicy.yaml"
  depends_on = [module.knative_gateway]
}

module "role" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/role.yaml"
  depends_on = [module.networkpolicy]
}

module "istio_resource" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/istio-resource.yaml"
  depends_on = [module.role]
}

module "pipeline_crds" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/pipeline-crds.yaml"
  depends_on = [module.istio_resource]
}

module "pipeline" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/pipeline.yaml"
  depends_on = [module.pipeline_crds]
}

module "kserve_crds" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/kserve-crds.yaml"
  depends_on = [module.pipeline]
}

resource "null_resource" "solve_deadlock" {
  provisioner "local-exec" {
    command = "kubectl patch crd/inferenceservices.serving.kserve.io -p '{\"metadata\":{\"finalizers\":[]}}' --type=merge"
  }
  depends_on = [module.kserve_crds]
}

module "kserve" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/kserve.yaml"
  depends_on = [module.kserve_crds]
}

module "kserve_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/kserve-web.yaml"
  depends_on = [module.kserve]
}

module "katib" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/katib.yaml"
  depends_on = [module.kserve_web]
}

module "centraldashboard" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/centraldashboard.yaml"
  depends_on = [module.katib]
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8002
  gateway   = "kubeflow-gateway"
  selector = {
    "app" = "centraldashboard"
  }
  depends_on = [module.centraldashboard]
}

module "admission_webhook" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/admission-webhook.yaml"
  depends_on = [module.centraldashboard]
}

module "notebook" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/notebook.yaml"
  depends_on = [module.admission_webhook]
}

module "notebook_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/notebook-web.yaml"
  depends_on = [module.notebook]
}

module "pvc_viewer" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/pvc-viewer.yaml"
  depends_on = [module.notebook_web]
}

module "profile" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/profile.yaml"
  depends_on = [module.pvc_viewer]
}

resource "time_sleep" "wait_profile" {
  create_duration = "60s"
  depends_on      = [module.profile]
}

module "volume_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/volume-web.yaml"
  depends_on = [time_sleep.wait_profile]
}

module "tensorboard" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/tensorboard.yaml"
  depends_on = [module.volume_web]
}

module "tensorboard_web" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/tensorboard-web.yaml"
  depends_on = [module.tensorboard]
}

module "training_operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/training-operator.yaml"
  depends_on = [module.tensorboard_web]
}

module "user" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/user.yaml"
  args = {
    email = var.email
  }
  depends_on = [module.training_operator]
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = <<EOF
      while true; do
        if [ $(kubectl get ns kubeflow-user 2> /dev/null | grep -c Active) -eq 1 ]
        then
            break
        else
            sleep 10
        fi
      done
    EOF
  }
  depends_on = [module.user]
}

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name      = "minio-secret"
    namespace = "kubeflow-user"
  }
  data = {
    AWS_ACCESS_KEY_ID     = var.minio_creds.username
    AWS_SECRET_ACCESS_KEY = var.minio_creds.password
  }
  depends_on = [null_resource.wait]
}

data "kubernetes_secret" "kubeconfig" {
  metadata {
    name      = "kubeconfig"
    namespace = "kube-system"
  }
  depends_on = [null_resource.wait]
}

resource "kubernetes_secret" "admin_config" {
  metadata {
    name      = "kubeconfig"
    namespace = "kubeflow-user"
  }
  data       = data.kubernetes_secret.kubeconfig.data
  depends_on = [null_resource.wait]
}

module "user_policy" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/user-policy.yaml"
  depends_on = [null_resource.wait]
}
