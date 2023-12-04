locals {
  prefix = "grafana"
}

variable "domain" {
  type = string
}

variable "mode" {
  type = string
}

variable "oidc" {
  type = object({
    client_id = string
    client_secret = string
  })
}
