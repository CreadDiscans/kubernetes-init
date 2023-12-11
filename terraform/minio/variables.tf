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

variable "minio_creds" {
  type = object({
    username = string
    password = string
  })
}
