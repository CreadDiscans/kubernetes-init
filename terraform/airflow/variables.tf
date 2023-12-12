locals {
  minio_url = "http://minio-gateway-service.minio-storage:9000"
}

variable "domain" {
  type = string
}

variable "prefix" {
  type = object({
    airflow = string
    gitlab  = string
  })
}

variable "password" {
  type = string
}

variable "minio_creds" {
  type = object({
    username = string
    password = string
  })
}
