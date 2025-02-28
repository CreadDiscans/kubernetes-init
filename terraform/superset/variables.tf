locals {
  prefix    = "superset"
  client_id = "superset"
  secretkey = random_password.password.result
}

resource "random_password" "password" {
  length = 16
  special = false
}

variable "domain" {
  type = string
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

output "auth" {
  value = module.oidc.auth
}
