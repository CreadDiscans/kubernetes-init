variable "namespace" {
  type = string
}

output "connection" {
  value = "redis://default:${random_password.password.result}@${kubernetes_service.redis_service.metadata.0.name}:6379"
}