variable "user" {
  type = string
}

variable "password" {
  type = string
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

output "host" {
  value = "${kubernetes_service.postgresql_service.metadata.0.name}.${var.namespace}"
}

output "port" {
  value = 5432
}