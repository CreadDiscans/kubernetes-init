locals {
    prefix = "argocd"
}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}

variable "oidc" {
  type = object({
    client_id     = string
    client_secret = string
  })
}
