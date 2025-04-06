locals {
  prefix    = "opencost"
  client_id = "opencost"
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

output "auth" {
  value = module.oidc.auth
}
