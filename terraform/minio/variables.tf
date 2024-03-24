variable "domain" {
  type = string
}

variable "prefix" {
  type = object({
    minio  = string
    gitlab = string
  })
}

variable "password" {
  type = string
}

variable "oidc" {
  type = object({
    client_id = string
    client_secret = string
  })
}

variable "minio_creds" {
  type = object({
    username = string
    password = string
  })
}
