locals {
  prefix        = "spark"
  client_id     = "spark"
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
    valid_redirect_uris = []
    valid_post_logout_redirect_uris = []
    base_url                        = ""
  }
}
