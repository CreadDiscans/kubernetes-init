locals {
  prefix        = "localscaler"
  client_id     = "localscaler"
  client_secret = "localscaler-secret"
}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}

output "client" {
  value = {
    client_id     = local.client_id
    client_secret = local.client_secret
    valid_redirect_uris = [
      "http://${local.prefix}.${var.domain}/oauth2/callback",
    ]
    valid_post_logout_redirect_uris = []
    base_url                        = ""
  }
}
