variable "domain" {
  type = string
}

variable "clients" {
  type = list(object({
    prefix        = string
    client_id     = string
    client_secret = string
  }))
}
