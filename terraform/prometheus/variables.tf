locals {
  prefix = "grafana"
  client_id = "grafana"
  client_secret = "grafana-secret"
}

variable "domain" {
  type = string
}

variable "mode" {
  type = string
}

output "client" {
  value = {
    client_id                       = local.client_id
    client_secret                   = local.client_secret
    valid_redirect_uris             = [
      "https://${local.prefix}.${var.domain}/login/generic_oauth",
      "https://${local.prefix}.${var.domain}/login",
    ]
    valid_post_logout_redirect_uris = []
    base_url                        = "https://${local.prefix}.${var.domain}"
  }
}