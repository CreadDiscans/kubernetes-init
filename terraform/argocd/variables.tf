locals {
  prefix    = "argocd"
  client_id = "argocd"
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
