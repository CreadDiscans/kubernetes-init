
variable "external_ips" {
  type    = string
  default = "x.x.x.x-x.x.x.x"
}

variable "email" {
  type    = string
  default = "user@example.com"
}

variable "nfs_ip" {
  type    = string
  default = "x.x.x.x"
}

variable "nfs_path" {
  type    = string
  default = "/nfs"
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "prefix" {
  type = object({
    keycloak = string
    gitlab   = string
    registry = string
    minio    = string
    grafana  = string
    argocd   = string
    airflow  = string
    kubeflow = string
  })
  default = {
    keycloak = "keycloak"
    gitlab   = "gitlab"
    registry = "registry"
    minio    = "minio"
    grafana  = "grafana"
    argocd   = "argocd"
    airflow  = "airflow"
    kubeflow = "kubeflow"
  }
}

variable "admin" {
  type = object({
    username = string
    password = string
  })
  default = {
    username = "admin"
    password = "admin"
  }
}

variable "airflow_repo" {
  type = string
}
