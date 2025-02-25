
module "oidc" {
  source = "../utils/oidc"
  keycloak = var.keycloak
  client_id = local.client_id
  prefix = local.prefix
  domain = var.domain
  redirect_uri = [
    "https://${local.prefix}.${var.domain}/keycloak/auth/callback"
  ]
  post_logout_redirect_uris = [
    "https://${local.prefix}.${var.domain}"
  ]
}