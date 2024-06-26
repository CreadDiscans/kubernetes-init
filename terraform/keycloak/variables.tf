locals {
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

variable "prefix" {
  type = string
}

variable "admin" {
  type = object({
    username = string
    password = string
  })
}

output "info" {
    value = {
        url = "https://${var.prefix}.${var.domain}"
        username = var.admin.username
        password = var.admin.password
    }
}