locals {
  client_id = "dashboard"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type    = string
  default = "dashboard"
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "grafana" {
  type = object({
    url  = string
    path = string
  })
}

variable "kubeflow_url" {
  type = string
}

output "auth" {
  value = module.oidc.auth
}
