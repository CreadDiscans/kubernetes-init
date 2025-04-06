locals {
  prefix    = "sysflow"
  client_id = "sysflow"

  db_user = "sysflow"
  db_name = "sysflow"
  db_password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length = 16
  special = false
}

variable "route" {
  type = object({
    domain = string
    issuer = string
    email  = string
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

variable "grafana" {
  type = object({
    url  = string
    path = string
  })
}

variable "kubeflow_url" {
  type = string
}

output "auth" {
  value = module.oidc.auth
}
