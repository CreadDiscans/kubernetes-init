locals {
  realm     = "master"
  client_id = "presto"
  prefix    = "presto"
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
