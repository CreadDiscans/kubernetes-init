resource "kubernetes_namespace" "ns" {
  metadata {
    name = "argocd"
  }
}

data "kubernetes_secret" "cert" {
  metadata {
    name      = "gitlab-cert"
    namespace = "gitlab-devops"
  }
}

module "config" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/config.yaml"
  args = {
    url           = "https://${local.prefix}.${var.domain}"
    client_id     = var.oidc.client_id
    client_secret = base64encode(var.oidc.client_secret)
    domain        = var.domain
    rootCA        = replace(data.kubernetes_secret.cert.data["tls.crt"], "\n", "\n      ")
  }
  depends_on = [kubernetes_namespace.ns]
}

module "install" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/install.yaml"
  depends_on = [module.config]
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  gateway   = true
  selector = {
    "app.kubernetes.io/name" = "argocd-server"
  }
  depends_on = [module.install]
}
