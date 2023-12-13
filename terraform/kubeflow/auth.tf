
module "oidc" {
  source       = "../utils/oidc"
  namespace    = "istio-system"
  gitlab_host  = local.gitlab_host
  password     = var.password
  redirect_uri = "https://${var.prefix.kubeflow}.${var.domain}/authservice_callback"
  name         = "kubeflow"
}

data "kubernetes_secret" "oidc_secret" {
  metadata {
    name      = module.oidc.secret
    namespace = "istio-system"
  }
  depends_on = [module.oidc]
}

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
        "prefix": "${var.prefix.kubeflow}",
      },
      "filters": [
      {
        "oidc":
          {
            "authorization_uri": "${local.gitlab_host}/oauth/authorize",
            "token_uri": "${local.gitlab_host}/oauth/token",
            "user_api_uri": "${local.gitlab_host}/api/v4/user/",
            "callback_uri": "https://${var.prefix.kubeflow}.${var.domain}/authservice_callback",
            "jwks_fetcher": {
              "jwks_uri": "${local.gitlab_host}/oauth/discovery/keys",
              "periodic_fetch_interval_sec": 10,
              "skip_verify_peer_cert": true
            },
            "client_id": "${data.kubernetes_secret.oidc_secret.data.client_id}",
            "client_secret": "${data.kubernetes_secret.oidc_secret.data.client_secret}",
            "cookie_name_prefix":"${var.prefix.kubeflow}",
            "scopes": ["openid", "email", "api"],
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
              "redirect_uri": "${local.gitlab_host}/users/sign_out"
            },
            "skip_verify_peer_cert": true,
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
