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
