locals {
  prefix   = "keycloak"
  username = "admin"
  password = random_password.password.result
  db = {
    name = "keycloak"
    user = "keycloak"
    password = random_password.password.result
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "domain" {
  type = string
}

output "info" {
  value = {
    url      = "https://${local.prefix}.${var.domain}"
    username = local.username
    password = local.password
  }
}
