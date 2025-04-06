locals {
  prefix = {
    gitlab   = "gitlab"
    registry = "registry"
  }
  client_id = "gitlab"
  password  = random_password.password.result
  db = {
    dbname   = "gitlab"
    user     = "gitlab"
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
    email  = string
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
