locals {
  prefix    = "kubeflow"
  client_id = "kubeflow"
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

output "url" {
  value = "https://${local.prefix}.${var.route.domain}"
}
