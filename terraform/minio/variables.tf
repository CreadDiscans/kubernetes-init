locals {
  username = "minioadmin"
  password = random_password.password.result
  realm = "master"
  client_id = "minio"
  client_secret = random_uuid.client_secret.result
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "client_secret" {}

variable "domain" {
  type = string
}

variable "prefix" {
  type = string
}

variable "keycloak" {
  type = object({
    url = string
    username = string
    password = string
  })
}
