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

resource "keycloak_group" "groups" {
  for_each = { for n in var.clients : n.client_id => n }
  realm_id = local.realm
  name     = each.value.client_id
  attributes = {
    policy = each.key == "minio" ? "consoleAdmin" : null
  }
}

resource "keycloak_user_groups" "user_groups" {
  realm_id  = local.realm
  user_id   = data.keycloak_user.root.id
  group_ids = [for g in keycloak_group.groups : g.id]
}

resource "keycloak_openid_client_scope" "auth" {
  for_each               = { for n in var.clients : n.client_id => n }
  realm_id               = local.realm
  name                   = "${each.key}-auth"
  description            = "for ${each.key}"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "auth_mapper" {
  for_each        = keycloak_openid_client_scope.auth
  realm_id        = local.realm
  client_scope_id = each.value.id
  name            = "groups"
  claim_name      = "groups"
}

resource "keycloak_openid_client_default_scopes" "default_scopes" {
  for_each  = { for n in keycloak_openid_client.openid_client : n.client_id => n }
  realm_id  = local.realm
  client_id = each.value.id
  default_scopes = [
    "email",
    "profile",
    "${each.key}-auth"
  ]
  depends_on = [keycloak_openid_group_membership_protocol_mapper.auth_mapper]
}
