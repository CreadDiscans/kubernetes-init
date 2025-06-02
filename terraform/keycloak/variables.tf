locals {
  prefix   = "keycloak"
  username = "admin"
  password = random_password.password.result
  db = {
    name     = "keycloak"
    user     = "keycloak"
    password = random_password.password.result
  }
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

output "info" {
  value = {
    url      = "https://${local.prefix}.${var.route.domain}"
    username = local.username
    password = local.password
  }
}
