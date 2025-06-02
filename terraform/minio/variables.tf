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

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
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
    url = "https://${local.prefix}-api.${var.route.domain}"
    username = local.username
    password = local.password
  }
}