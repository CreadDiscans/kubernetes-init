locals {
  prefix        = "minio"
  client_id     = "minio"
  client_secret = "minio-secret"
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}

output "client" {
  value = {
    client_id                       = local.client_id
    client_secret                   = local.client_secret
    valid_redirect_uris             = [
      "https://${local.prefix}.${var.domain}/oauth_callback",
    ]
    valid_post_logout_redirect_uris = []
    base_url                        = ""
  }
}
