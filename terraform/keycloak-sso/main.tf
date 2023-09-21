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
    keycloak_group.minio_group.id
  ]
}

# module "authservice" {
#   source = "../utils/apply"
#   yaml   = "${path.module}/yaml/authservice.yaml"
#   args = {
#     client_id     = local.client_id
#     client_secret = local.client_secret
#   }
# }
