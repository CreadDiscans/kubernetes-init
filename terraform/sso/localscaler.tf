module "oauth2_proxy" {
  for_each = { for n in var.clients : n.client_id => n if n.client_id == "localscaler" }
  source   = "../utils/apply"
  yaml     = "${path.module}/yaml/oauth2-proxy.yaml"
  args = {
    upstream      = "http://localscaler-service.autoscaler"
    issuer        = "https://keycloak.${var.domain}/realms/master"
    client_id     = each.value.client_id
    client_secret = each.value.client_secret
  }
  unique = each.key
}
