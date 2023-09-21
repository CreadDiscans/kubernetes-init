locals {
  realm = "master"
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "url" {
  type = string
}

variable "clients" {
  type = list(object({
    client_id                       = string
    client_secret                   = string
    valid_redirect_uris             = list(string)
    valid_post_logout_redirect_uris = list(string)
    base_url                        = string
  }))
}
