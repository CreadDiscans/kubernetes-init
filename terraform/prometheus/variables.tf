locals {
  prefix = "grafana"
  client_id = "grafana"
}

variable "domain" {
  type = string
}

variable "keycloak" {
  type = object({
    url = string
    username = string
    password = string
  })
}