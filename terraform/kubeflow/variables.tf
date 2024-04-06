locals {
  realm = "master"
  client_id = "kubeflow"
  client_secret = random_uuid.client_secret.result
}

resource "random_uuid" "client_secret" {}

variable "domain" {
  type = string
}

variable "prefix" {
  type = string
}

variable "email" {
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