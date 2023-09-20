resource "kubernetes_namespace" "ns" {
  metadata {
    name = "istio-system"
  }
}
module "crds_operator" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/crd-operator.yaml"
}

module "istio_operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/istio-operator.yaml"
  depends_on = [module.crds_operator]
}

module "default_operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/default-operator.yaml"
  depends_on = [module.istio_operator]
}
