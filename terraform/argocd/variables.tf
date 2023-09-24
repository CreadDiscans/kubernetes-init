locals {
    prefix = "argocd"
    client_id = "argocd"
    client_secret = random_uuid.client_secret.result
}

resource "random_uuid" "client_secret" {}

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
      "https://${local.prefix}.${var.domain}/auth/callback",
    ]
    valid_post_logout_redirect_uris = []
    base_url                        = ""
  }
}
