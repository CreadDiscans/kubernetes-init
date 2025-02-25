locals {
  config_template = <<EOF
{
    "name": "oidc",
    "match": {
        "header": ":authority",
        "prefix": "$${auth.prefix}"
    },
    "filters": [
        {
            "oidc": {
                "configuration_uri": "$${auth.keycloak.url}/realms/$${auth.realm}/.well-known/openid-configuration",
                "callback_uri": "https://$${auth.prefix}.$${auth.domain}/authservice_callback",
                "jwks_fetcher": {
                    "jwks_uri": "$${auth.keycloak.url}/realms/$${auth.realm}/protocol/openid-connect/certs"
                },
                "client_id": "$${auth.client_id}",
                "client_secret": "$${auth.client_secret}",
                "cookie_name_prefix":"$${auth.client_id}",
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
                    "redirect_uri": "$${auth.keycloak.url}/realms/$${auth.realm}/protocol/openid-connect/logout"
                },
                "group":"/$${auth.client_id}"
            }
        }
    ]
}
EOF
    
    config_chains = join(",", [for auth in var.auths : templatestring(local.config_template, { 
        auth = auth 
    })])
}


variable "auths" {
  type = list(object({
    realm = string
    prefix = string
    domain = string
    client_id = string
    client_secret = string
    keycloak = object({
      url = string
      username = string
      password = string
    })
  }))
}