resource "kubernetes_namespace" "ns" {
  metadata {
    name = "reloader"
  }
}

module "reloader" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/reloader.yaml"
  depends_on = [kubernetes_namespace.ns]
}
