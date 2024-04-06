
# module "oidc" {
#   source       = "../utils/oidc"
#   namespace    = "istio-system"
#   gitlab_host  = local.gitlab_host
#   password     = var.password
#   redirect_uri = "https://${var.prefix.kubeflow}.${var.domain}/authservice_callback"
#   name         = "kubeflow"
# }

# data "kubernetes_secret" "oidc_secret" {
#   metadata {
#     name      = module.oidc.secret
#     namespace = "istio-system"
#   }
#   depends_on = [module.oidc]
# }

resource "kubernetes_config_map" "authservice_configmap" {
  metadata {
    name      = "authservice"
    namespace = "istio-system"
  }
  data = {
    "config.json" = <<EOF
{
  "listen_address": "0.0.0.0",
  "listen_port": "10003",
  "log_level": "trace",
  "threads": 8,
  "allow_unmatched_requests": "false",
  "chains": [{
      "name": "idp_filter_chain",
      "match": {
        "header": ":authority",
        "prefix": "${var.prefix}",
      },
      "filters": [
      {
        "oidc":
          {
            "authorization_uri": "${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/auth",
            "token_uri": "${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/token",
            "callback_uri": "https://${var.prefix}.${var.domain}/authservice_callback",
            "jwks_fetcher": {
              "jwks_uri": "${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/certs",
              "periodic_fetch_interval_sec": 10,
              "skip_verify_peer_cert": true
            },
            "client_id": "${local.client_id}",
            "client_secret": "${local.client_secret}",
            "cookie_name_prefix":"${local.client_id}",
            "scopes": [],
            "id_token": {
              "preamble": "Bearer",
              "header": "Authorization"
            },
            "access_token": {
              "preamble": "Bearer",
              "header": "Authorization"
            },
            "logout": {
              "path": "/authservice_logout",
              "redirect_uri": "${var.keycloak.url}/realms/${local.realm}/protocol/openid-connect/logout"
            },
            "skip_verify_peer_cert": true,
            "group":"/${local.client_id}",
            "error_uri":"${var.keycloak.url}/403"

          }
        }
      ]
    }
  ]
}
    EOF
  }
}

module "authservice" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/authservice.yaml"
  depends_on = [kubernetes_config_map.authservice_configmap]
}
