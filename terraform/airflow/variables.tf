locals {
  password  = random_password.password.result
  prefix    = "airflow"
  client_id = "airflow"
}

resource "random_password" "password" {
  length = 16
}

variable "domain" {
  type = string
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
