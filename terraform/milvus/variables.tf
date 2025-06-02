locals {
  prefix = "milvus"
  client_id = "milvus"
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