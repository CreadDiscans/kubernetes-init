variable "minio_creds" {
    type = object({
      url = string
      username = string
      password = string
    })
}