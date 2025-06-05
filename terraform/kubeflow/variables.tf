locals {
  client_id = "kubeflow"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type    = string
  default = "kubeflow"
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "email" {
  type = string
}

output "auth" {
  value = module.oidc.auth
}

output "url" {
  value = "https://${var.prefix}.${var.route.domain}"
}
