locals {
  password = random_password.password.result
  realm = "master"
  client_id = "airflow"
  client_secret = random_uuid.client_secret.result
}

resource "random_password" "password" {
  length           = 16
}

resource "random_uuid" "client_secret" {}

variable "domain" {
  type = string
}

variable "prefix" {
  type = string
}

variable "minio_creds" {
  type = object({
    url = string
    username = string
    password = string
  })
}

variable "keycloak" {
  type = object({
    url = string
    username = string
    password = string
  })
}

variable "airflow_repo" {
  type = string
}