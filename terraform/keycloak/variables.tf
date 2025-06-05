locals {
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

variable "prefix" {
  type    = string
  default = "keycloak"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

output "info" {
  value = {
    url      = "https://${var.prefix}.${var.route.domain}"
    username = local.username
    password = local.password
  }
}
