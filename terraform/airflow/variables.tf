locals {
  password  = random_password.password.result
  client_id = "airflow"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type    = string
  default = "airflow"
}

variable "minio_creds" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "airflow_repo" {
  type = string
}
