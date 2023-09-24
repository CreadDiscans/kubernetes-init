resource "keycloak_openid_client_scope" "grafana_auth" {
    realm_id = local.realm
    name = "grafana-auth"
    description = "for grafana"
    include_in_token_scope = true
    gui_order = 1
}

resource "keycloak_openid_group_membership_protocol_mapper" "grafana_auth_mapper" {
  realm_id  = local.realm
  client_scope_id = keycloak_openid_client_scope.grafana_auth.id
  name      = "groups"

  claim_name = "groups"
}

resource "keycloak_openid_client_default_scopes" "grafana_scopes" {
  for_each  = { for n in keycloak_openid_client.openid_client : n.client_id => n if n.client_id == "grafana" }
  realm_id  = local.realm
  client_id = each.value.id
  default_scopes = [
    "email",
    "profile",
    keycloak_openid_client_scope.grafana_auth.name
  ]
}

resource "keycloak_group" "grafana_group" {
  realm_id = local.realm
  name     = "grafana"
}

