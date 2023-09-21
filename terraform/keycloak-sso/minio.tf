
resource "keycloak_openid_client_scope" "minio_auth" {
  realm_id               = local.realm
  name                   = "minio-authorization"
  description            = "for minio"
  include_in_token_scope = true
  gui_order              = 1
}

resource "keycloak_openid_user_attribute_protocol_mapper" "minio_auth_mapper" {
  realm_id             = local.realm
  client_scope_id      = keycloak_openid_client_scope.minio_auth.id
  name                 = "minio-policy-mapper"
  user_attribute       = "policy"
  claim_name           = "policy"
  add_to_id_token      = true
  claim_value_type     = "String"
  multivalued          = true
  aggregate_attributes = true
}

resource "keycloak_openid_client_default_scopes" "minio_scopes" {
  for_each  = { for n in keycloak_openid_client.openid_client : n.client_id => n if n.client_id == "minio" }
  realm_id  = local.realm
  client_id = each.value.id
  default_scopes = [
    "email",
    keycloak_openid_client_scope.minio_auth.name
  ]
}

resource "keycloak_group" "minio_group" {
  realm_id = local.realm
  name     = "minio"
  attributes = {
    policy = "consoleAdmin"
  }
}

