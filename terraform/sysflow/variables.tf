locals {
    prefix = "geodev"
    client_id = "sysflow"
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