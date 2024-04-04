resource "keycloak_openid_client" "openid_client" {
  realm_id                        = local.realm
  client_id                       = local.client_id
  name                            = local.client_id
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  client_secret                   = local.client_secret
  direct_access_grants_enabled    = true
  standard_flow_enabled           = true
  valid_redirect_uris             = ["https://${var.prefix}.${var.domain}/oauth_callback"]
  valid_post_logout_redirect_uris = []
  base_url                        = ""
  root_url                        = ""
  access_token_lifespan           = 86400
}

data "keycloak_user" "root" {
  realm_id = local.realm
  username = var.keycloak.username
}

resource "keycloak_group" "group" {
  realm_id = local.realm
  name     = local.client_id
  attributes = {
    policy = "consoleAdmin"
  }
}

resource "keycloak_user_groups" "user_groups" {
  realm_id  = local.realm
  user_id   = data.keycloak_user.root.id
  group_ids = [keycloak_group.group.id]
}

resource "keycloak_openid_client_scope" "auth" {
  realm_id               = local.realm
  name                   = "${local.client_id}-auth"
  description            = "for ${local.client_id}"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "auth_mapper" {
  realm_id        = local.realm
  client_scope_id = keycloak_openid_client_scope.auth.id
  name            = "groups"
  claim_name      = "groups"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "minio_auth_mapper" {
  realm_id             = local.realm
  client_scope_id      = keycloak_openid_client_scope.auth.id
  name                 = "minio-policy-mapper"
  user_attribute       = "policy"
  claim_name           = "policy"
  add_to_id_token      = true
  claim_value_type     = "String"
  multivalued          = true
  aggregate_attributes = true
}

resource "keycloak_openid_client_default_scopes" "default_scopes" {
  realm_id  = local.realm
  client_id = keycloak_openid_client.openid_client.id
  default_scopes = [
    "email",
    "profile",
    "${local.client_id}-auth"
  ]
  depends_on = [keycloak_openid_group_membership_protocol_mapper.auth_mapper]
}
