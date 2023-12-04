locals {
  prefix        = "airflow"
  minio_url     = "http://minio-gateway-service.minio-storage:9000"
}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}

variable "git_repo" {
  type = string
}

variable "oidc" {
  type = object({
    client_id     = string
    client_secret = string
  })
}