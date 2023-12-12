locals {
  minio_creds = {
    username = "minioadmin"
    password = random_password.minio_password.result
  }
}

resource "random_password" "minio_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "external_ips" {
  type    = string
  default = "x.x.x.x-x.x.x.x"
}

variable "email" {
  type    = string
  default = "user@example.com"
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "nfs_ip" {
  type    = string
  default = "x.x.x.x"
}

variable "nfs_path" {
  type    = string
  default = "/nfs"
}

variable "password" {
  type    = string
  default = "defaultpassword"
}

variable "prefix" {
  type = object({
    gitlab   = string
    registry = string
    minio    = string
    grafana  = string
    argocd   = string
  })
  default = {
    gitlab   = "gitlab"
    registry = "registry"
    minio    = "minio"
    grafana  = "grafana"
    argocd   = "argocd"
  }
}

# variable "airflow_repo" {
#   type    = string
#   default = ""
# }

# variable "minio_oidc" {
#   type = object({
#     client_id     = string
#     client_secret = string
#   })
# }

# variable "grafana_oidc" {
#   type = object({
#     client_id     = string
#     client_secret = string
#   })
# }

# variable "argocd_oidc" {
#   type = object({
#     client_id     = string
#     client_secret = string
#   })
# }

# variable "airflow_oidc" {
#   type = object({
#     client_id     = string
#     client_secret = string
#   })
# }

# variable "kubeflow_oidc" {
#   type = object({
#     client_id     = string
#     client_secret = string
#   })
# }
