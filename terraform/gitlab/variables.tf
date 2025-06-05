locals {
  client_id = "gitlab"
  password  = random_password.password.result
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
    gitlab   = "gitlab"
    registry = "registry"
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

output "gitlab_url" {
  value = "https://${local.prefix.gitlab}.${var.route.domain}"
}
