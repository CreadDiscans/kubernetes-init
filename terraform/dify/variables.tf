locals {
  bucket_name = "dify-storage"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type = object({
    console = string
    api     = string
  })
  default = {
    console = "dify"
    api     = "dify-api"
  }
}

variable "minio_creds" {
  type = object({
    url      = string
    username = string
    password = string
  })
}
