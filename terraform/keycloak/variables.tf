locals {
  prefix        = "keycloak"
  clusterissuer = var.mode == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"
}

variable "domain" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "mode" {
  type = string
}
