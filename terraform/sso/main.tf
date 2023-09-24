resource "keycloak_openid_client" "openid_client" {
  for_each                        = { for n in var.clients : n.client_id => n }
  realm_id                        = local.realm
  client_id                       = each.value.client_id
  name                            = each.value.client_id
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  client_secret                   = each.value.client_secret
  direct_access_grants_enabled    = true
  standard_flow_enabled           = true
  valid_redirect_uris             = each.value.valid_redirect_uris
  valid_post_logout_redirect_uris = each.value.valid_post_logout_redirect_uris
  base_url                        = each.value.base_url
  root_url                        = each.value.base_url
  access_token_lifespan           = 86400
}

data "keycloak_user" "root" {
  realm_id = local.realm
  username = var.username
}

resource "keycloak_user_groups" "user_groups" {
  realm_id = local.realm
  user_id  = data.keycloak_user.root.id
  group_ids = [
    keycloak_group.minio_group.id,
    keycloak_group.grafana_group.id,
    keycloak_group.argocd_group.id
  ]
}

module "oauth2_proxy" {
  for_each = { for n in keycloak_openid_client.openid_client : n.client_id => n if n.client_id == "localscaler" }
  source   = "../utils/apply"
  yaml     = "${path.module}/yaml/oauth2-proxy.yaml"
  args = {
    upstream      = "http://localscaler-service.autoscaler"
    issuer        = "https://keycloak.${var.domain}/realms/master"
    client_id     = each.value.client_id
    client_secret = each.value.client_secret
  }
}
