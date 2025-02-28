resource "kubernetes_namespace" "ns" {
  metadata {
    name = "vitess"
  }
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/operator.yaml"
  depends_on = [kubernetes_namespace.ns]
}

# module "vitess" {
#   source = "../utils/apply"
#   yaml   = "${path.module}/yaml/vitess.yaml"
#   args = {
#     infos = var.keyspaces
#   }
#   depends_on = [kubernetes_namespace.ns]
# }

