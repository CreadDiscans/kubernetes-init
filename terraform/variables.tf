
variable "external_ips" {
  type    = string
  default = "x.x.x.x-x.x.x.x"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
  default = {
    domain = "example.com"
    issuer = "letsencrypt-staging"
  }
}

variable "aws_key" {
  type = object({
    aws_access_key_id     = string
    aws_secret_access_key = string
  })
  default = {
    aws_access_key_id     = ""
    aws_secret_access_key = ""
  }
}

variable "osd" {
  type = list(object({
    node    = string
    devices = list(string)
  }))
  default = []
}

variable "single_node" {
  type    = bool
  default = true
}

variable "nfs_info" {
  type = object({
    ip   = string
    path = string
  })
  default = {
    ip   = "x.x.x.x"
    path = "/nfs"
  }
}

variable "airflow_repo" {
  type    = string
  default = "/system/airflow.git"
}

variable "dns_records" {
  type    = string
  default = "" # x.x.x.x example.com
}

variable "email" {
  type    = string
  default = "user@example.com"
}

variable "cloudflared_token" {
  type    = string
  default = ""
}

variable "prefix" {
  type = object({
    keycloak  = string
    grafana   = string
    argocd    = string
    minio     = string
    minio_api = string
    gitlab    = string
    registry  = string
    kubeflow  = string
    airflow   = string
    milvus    = string
    spark     = string
    jenkins   = string
    presto    = string
    opencost  = string
    superset  = string
    dashboard = string
    kubeai    = string
    dify      = string
    dify_api  = string
  })
  default = {
    keycloak  = "keycloak"
    grafana   = "grafana"
    argocd    = "argocd"
    minio     = "minio"
    minio_api = "minio-api"
    gitlab    = "gitlab"
    registry  = "registry"
    kubeflow  = "kubeflow"
    airflow   = "airflow"
    milvus    = "milvus"
    spark     = "spark"
    jenkins   = "jenkins"
    presto    = "presto"
    opencost  = "opencost"
    superset  = "superset"
    dashboard = "dashboard"
    kubeai    = "kubeai"
    dify      = "dify"
    dify_api  = "dify_api"
  }
}
