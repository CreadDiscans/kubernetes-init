locals {
  username = "minioadmin"
  password = random_password.password.result
  prefix = "minio"
  client_id = "minio"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "domain" {
  type = string
}

variable "keycloak" {
  type = object({
    url = string
    username = string
    password = string
  })
}

output "creds" {
  value = {
    url = "https://${local.prefix}-api.${var.domain}"
    username = local.username
    password = local.password
  }
}