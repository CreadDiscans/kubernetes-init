variable "domain" {
  type = string
}

variable "prefix" {
  type = object({
    grafana = string
    gitlab = string
  })
}

variable "password" {
  type = string
}

variable "oidc" {
  type = object({
    client_id = string
    client_secret = string
  })
}