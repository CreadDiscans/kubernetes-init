locals {
  username  = "minioadmin"
  password  = random_password.password.result
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

variable "prefix" {
  type = object({
    console = string
    api     = string
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

output "creds" {
  value = {
    url      = module.service_api.internal_url
    username = local.username
    password = local.password
  }
}
