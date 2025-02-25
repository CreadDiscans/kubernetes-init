locals {
  prefix    = "argocd"
  client_id = "argocd"
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
