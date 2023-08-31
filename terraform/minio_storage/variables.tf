locals {
  prefix        = "minio"
  clusterissuer = var.mode == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "nfs_ip" {
  type = string
}

variable "nfs_path" {
  type = string
}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}
