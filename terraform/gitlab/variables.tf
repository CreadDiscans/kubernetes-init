locals {
  password = random_password.password.result
  realm = "master"
  client_id = "gitlab"
  client_secret = random_uuid.client_secret.result
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "client_secret" {}

variable "prefix" {
  type = object({
    gitlab = string
    registry = string
  })
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

output "url" {
  value = "https://${var.prefix.gitlab}.${var.domain}"
}