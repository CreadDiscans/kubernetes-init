resource "kubernetes_namespace" "ns" {
  metadata {
    labels = {
      "pod-security.kubernetes.io/warn" : "privileged"
      "pod-security.kubernetes.io/warn-version" : "latest"
    }
    name = "monitoring"
  }
}

module "setup" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/setup"
  depends_on = [kubernetes_namespace.ns]
}

resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [module.setup]
}


module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests"
  depends_on = [time_sleep.wait]
}


