locals {
  prefix = "kubeflow"
  client_id = "kubeflow"
}

variable "domain" {
  type = string
}

variable "email" {
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
