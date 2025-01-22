resource "kubernetes_namespace" "ns_cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

module "cert_manager" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/cert-manager-v1.16.3.yaml"
  depends_on = [kubernetes_namespace.ns_cert_manager]
}

resource "time_sleep" "wait_cert_manager" {
  create_duration = "200s"
  depends_on      = [module.cert_manager]
}

module "cert_cluster_issuer" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cluster-issuer.yaml"
  args = {
    email = var.email
  }
  depends_on = [time_sleep.wait_cert_manager]
}
