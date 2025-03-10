locals {
  prefix        = "spark"
  client_id     = "spark"
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

output "auth" {
  value = module.oidc.auth
}