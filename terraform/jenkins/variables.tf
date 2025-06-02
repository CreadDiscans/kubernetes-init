locals {
  prefix = "jenkins"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}
