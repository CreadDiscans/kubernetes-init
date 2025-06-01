resource "kubernetes_namespace" "ns_cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

module "cert_manager" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/cert-manager-v1.17.2.yaml"
  depends_on = [kubernetes_namespace.ns_cert_manager]
}

resource "time_sleep" "wait_cert_manager" {
  create_duration = "200s"
  depends_on      = [module.cert_manager]
}

module "cert_cluster_issuer" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cluster-issuer.yaml"
  depends_on = [time_sleep.wait_cert_manager]
}

resource "kubernetes_secret" "aws_secret" {
  count = var.aws_key.aws_access_key_id == "" ? 0 : 1
  metadata {
    name      = "route53-credentials-secret"
    namespace = kubernetes_namespace.ns_cert_manager.metadata.0.name
  }
  data = {
    aws_access_key_id     = var.aws_key.aws_access_key_id
    aws_secret_access_key = var.aws_key.aws_secret_access_key
  }
}

module "dns_cluster_issuer" {
  count  = var.aws_key.aws_access_key_id == "" ? 0 : 1
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cluster-issuer-dns.yaml"
  depends_on = [kubernetes_secret.aws_secret]
}

