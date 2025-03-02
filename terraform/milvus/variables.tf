locals {
  prefix = "milvus"
  client_id = "milvus"
}

variable "domain" {
  type = string
}

# variable "minio_creds" {
#   type = object({
#     url = string
#     username = string
#     password = string
#   })
# }

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

output "auth" {
  value = module.oidc.auth
}