locals {
  prefix    = "langfuse"
  client_id = "langfuse"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
    email  = string
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "minio_creds" {
  type = object({
    url      = string
    username = string
    password = string
  })
}