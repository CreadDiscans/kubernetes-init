locals {
  gitlab_host = "https://${var.prefix.gitlab}.${var.domain}"
}

variable "domain" {
  type = string
}

variable "prefix" {
  type = object({
    kubeflow = string
    gitlab   = string
  })
}

variable "password" {
  type = string
}

variable "email" {
  type = string
}

variable "minio_creds" {
  type = object({
    username = string
    password = string
  })
}
