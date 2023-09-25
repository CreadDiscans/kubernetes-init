resource "keycloak_openid_user_attribute_protocol_mapper" "minio_auth_mapper" {
  realm_id             = local.realm
  client_scope_id      = keycloak_openid_client_scope.auth["minio"].id
  name                 = "minio-policy-mapper"
  user_attribute       = "policy"
  claim_name           = "policy"
  add_to_id_token      = true
  claim_value_type     = "String"
  multivalued          = true
  aggregate_attributes = true
}
