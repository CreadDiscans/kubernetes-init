resource "kubernetes_namespace" "ns" {
  metadata {
    name = "redis"
  }
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/operator.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "cluster" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/cluster.yaml"
  depends_on = [module.operator]
}
