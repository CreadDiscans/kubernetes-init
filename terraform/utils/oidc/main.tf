resource "keycloak_openid_client" "openid_client" {
  realm_id                        = var.realm
  client_id                       = var.client_id
  name                            = var.client_id
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  client_secret                   = local.client_secret
  direct_access_grants_enabled    = true
  standard_flow_enabled           = true
  valid_redirect_uris             = [for uri in var.redirect_uri : (uri == "default" ? "https://${var.prefix}.${var.domain}/authservice_callback" : uri)]
  valid_post_logout_redirect_uris = var.post_logout_redirect_uris
  base_url                        = ""
  root_url                        = ""
  access_token_lifespan           = 86400
}

resource "keycloak_group" "group" {
  realm_id = var.realm
  name     = var.client_id
  attributes = {
    policy = var.policy
  }
}

resource "keycloak_openid_client_scope" "auth" {
  realm_id               = var.realm
  name                   = "${var.client_id}-auth"
  description            = "for ${var.client_id}"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "auth_mapper" {
  realm_id        = var.realm
  client_scope_id = keycloak_openid_client_scope.auth.id
  name            = "groups"
  claim_name      = "groups"
}

resource "keycloak_openid_audience_protocol_mapper" "audience_mapper" {
  realm_id  = var.realm
  client_scope_id = keycloak_openid_client_scope.auth.id
  name      = "audience-mapper"
  included_client_audience = var.client_id
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "realm_role_mapper" {
  realm_id = var.realm
  client_scope_id = keycloak_openid_client_scope.auth.id
  name = "realm-role-mapper"
  claim_name = "role"
  multivalued = true
}

resource "keycloak_openid_user_attribute_protocol_mapper" "auth_mapper" {
  count                = var.policy == "" ? 0 : 1
  realm_id             = var.realm
  client_scope_id      = keycloak_openid_client_scope.auth.id
  name                 = "${var.client_id}-policy-mapper"
  user_attribute       = "policy"
  claim_name           = "policy"
  add_to_id_token      = true
  claim_value_type     = "String"
  multivalued          = true
  aggregate_attributes = true
}

resource "keycloak_openid_client_default_scopes" "default_scopes" {
  realm_id  = var.realm
  client_id = keycloak_openid_client.openid_client.id
  default_scopes = [
    "email",
    "profile",
    "${var.client_id}-auth"
  ]
  depends_on = [keycloak_openid_group_membership_protocol_mapper.auth_mapper]
}
