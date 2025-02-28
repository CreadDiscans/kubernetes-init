resource "kubernetes_namespace" "ns_op" {
  metadata {
    name = "minio-operator"
  }
}

module "minio" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/minio.yaml"
  depends_on = [kubernetes_namespace.ns_op]
}

resource "kubernetes_namespace" "ns_tenant" {
  metadata {
    name = "minio-tenant"
  }
}

module "tenant" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/tenant-base.yaml"
  args = {
    username      = local.username
    password      = local.password
    keycloak      = module.oidc.auth.keycloak
    client_id     = module.oidc.auth.client_id
    client_secret = module.oidc.auth.client_secret
    realm         = module.oidc.auth.realm
  }
  depends_on = [kubernetes_namespace.ns_tenant, module.minio]
}

resource "kubernetes_ingress_v1" "web_ingress" {
  metadata {
    name      = "minio-ingress"
    namespace = kubernetes_namespace.ns_tenant.metadata.0.name
    annotations = {
      "cert-manager.io/cluster-issuer"                     = "letsencrypt-prod"
      "kubernetes.io/ingress.class"                        = "nginx"
      "nginx.ingress.kubernetes.io/proxy-ssl-verify"       = "off"
      "nginx.ingress.kubernetes.io/backend-protocol"       = "HTTPS"
      "nginx.ingress.kubernetes.io/rewrite-target"         = "/"
      "nginx.ingress.kubernetes.io/proxy-body-size"        = "0"
      "nginx.ingress.kubernetes.io/affinity"               = "cookie"
      "nginx.ingress.kubernetes.io/session-cookie-hash"    = "sha1"
      "nginx.ingress.kubernetes.io/session-cookie-name"    = "route"
      "nginx.ingress.kubernetes.io/session-cookie-max-age" = "172800"
      "sysflow/favicon"                                    = "/favicon-32x32.png"
      "sysflow/doc"                                        = "https://min.io/docs/minio/kubernetes/upstream/administration/minio-console.html"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["${local.prefix}.${var.domain}"]
      secret_name = "${local.prefix}-cert"
    }
    rule {
      host = "${local.prefix}.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "myminio-console"
              port {
                number = 9443
              }
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_ingress_v1" "api_ingress" {
  metadata {
    name      = "minio-api-ingress"
    namespace = kubernetes_namespace.ns_tenant.metadata.0.name
    annotations = {
      "cert-manager.io/cluster-issuer"               = "letsencrypt-prod"
      "kubernetes.io/ingress.class"                  = "nginx"
      "nginx.ingress.kubernetes.io/proxy-ssl-verify" = "off"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "nginx.ingress.kubernetes.io/rewrite-target"   = "/"
      "nginx.ingress.kubernetes.io/proxy-body-size"  = "0"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["${local.prefix}-api.${var.domain}"]
      secret_name = "${local.prefix}-api-cert"
    }
    rule {
      host = "${local.prefix}-api.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "minio"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }
}

module "oidc" {
  source       = "../utils/oidc"
  keycloak     = var.keycloak
  client_id    = local.client_id
  prefix       = local.prefix
  domain       = var.domain
  policy       = "consoleAdmin"
  redirect_uri = ["https://${local.prefix}.${var.domain}/oauth_callback"]
}
