locals {
  client_id = "argocd"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type    = string
  default = "argocd"
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}
