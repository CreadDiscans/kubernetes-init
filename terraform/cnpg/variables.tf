variable "minio_creds" {
    type = object({
      username = string
      password = string
    })
}