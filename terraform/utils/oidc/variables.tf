locals {
  secret_name = "oidc-secret"
}

variable "namespace" {
  type = string
}

variable "gitlab_host" {
  type = string
}

variable "password" {
  type = string
}

variable "redirect_uri" {
  type = string
}

variable "name" {
  type = string
}

output "secret" {
    value = local.secret_name
}