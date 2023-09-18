resource "kubernetes_namespace" "ns" {
  metadata {
    name = "istio-system"
  }
}

module "crds" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/crd-all.gen.yaml"
}

module "istio_base" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/istio-base.yaml"
  depends_on = [kubernetes_namespace.ns, module.crds]
}

module "istiod" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/istiod.yaml"
  depends_on = [module.istio_base]
}

module "istio-gateway" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/istio-gateway.yaml"
  depends_on = [module.istiod]
}
