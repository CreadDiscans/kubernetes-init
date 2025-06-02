locals {
  realm     = "master"
  client_id = "presto"
  prefix    = "presto"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
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
