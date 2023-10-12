locals {
  prefix        = "airflow"
  minio_url     = "http://minio-gateway-service.minio-storage:9000"
  client_id     = "airflow"
  client_secret = random_uuid.client_secret.result
}

resource "random_uuid" "client_secret" {}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}

variable "git_repo" {
  type = string
}

output "client" {
  value = {
    client_id     = local.client_id
    client_secret = local.client_secret
    valid_redirect_uris = []
    valid_post_logout_redirect_uris = []
    base_url                        = ""
  }
}
