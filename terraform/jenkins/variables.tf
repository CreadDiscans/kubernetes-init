locals {
  client_id = "jenkins"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type    = string
  default = "jenkins"
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}
