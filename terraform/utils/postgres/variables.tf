locals {
  password = var.password == "" ? random_password.password.result : var.password
}

resource "random_password" "password" {
  special = false
  length  = 16
}

variable "user" {
  type = string
}

variable "password" {
  type    = string
  default = ""
}

variable "name" {
  type = string
}

variable "storage" {
  type    = string
  default = "8Gi"
}

variable "namespace" {
  type = string
}

variable "config" {
  type    = map(string)
  default = {}
}

output "host" {
  value = "${kubernetes_service.postgresql_service.metadata.0.name}.${var.namespace}"
}

output "port" {
  value = 5432
}

output "user" {
  value = var.user
}

output "name" {
  value = var.name
}

output "password" {
  value = local.password
}

output "connection" {
  value = "postgresql://${var.user}:${local.password}@${kubernetes_service.postgresql_service.metadata.0.name}:5432/${var.name}"
}
