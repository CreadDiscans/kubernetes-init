module "config" {
  for_each = { for n in var.clients : n.client_id => n if n.client_id == "localscaler" }
  source   = "../utils/apply"
  yaml     = "${path.module}/yaml/config.yaml"
  args = {
    prefix        = each.value.client_id
    client_id     = each.value.client_id
    client_secret = each.value.client_secret
    domain        = var.domain
    redirect_uri  = each.value.valid_redirect_uris.0
  }
}

module "authservice" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/authservice.yaml"
  depends_on = [module.config]
}
