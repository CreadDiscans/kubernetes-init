variable "namespace" {
  type = string
}

variable "storage" {
  type    = string
  default = "10Gi"
}

variable "password" {
  type = bool
  default = true
}

output "connection" {
  value = "redis://default:${random_password.password.result}@${kubernetes_service.redis_service.metadata.0.name}:6379"
}

output "host" {
  value = "${kubernetes_service.redis_service.metadata.0.name}.${var.namespace}"
}

output "port" {
  value = 6379
}

output "password" {
  value = random_password.password.result
}
