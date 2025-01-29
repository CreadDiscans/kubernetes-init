locals {

}

variable "domain" {
  type = string
}

variable "prefix" {
  type = string
}

variable "minio_creds" {
  type = object({
    url = string
    username = string
    password = string
  })
}