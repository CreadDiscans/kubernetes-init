locals {
  client_secret = random_uuid.client_secret.result
}

resource "random_uuid" "client_secret" {}

variable "realm" {
  type    = string
  default = "master"
}

variable "client_id" {
  type = string
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "prefix" {
  type = string
}

variable "domain" {
  type = string
}

variable "redirect_uri" {
  type    = list(string)
  default = ["default"]
}

variable "post_logout_redirect_uris" {
  type = list(string)
  default = []  
}

variable "policy" {
  type    = string
  default = ""
}

output "wellKnown" {
  value = "${var.keycloak.url}/realms/master/.well-known/openid-configuration"
}

output "auth" {
  value = {
    realm         = var.realm
    prefix        = var.prefix
    domain        = var.domain
    client_id     = var.client_id
    client_secret = local.client_secret
    keycloak      = var.keycloak
  }
}
