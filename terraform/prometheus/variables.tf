locals {
  realm = "master"
  client_id = "grafana"
  client_secret = random_uuid.client_secret.result
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