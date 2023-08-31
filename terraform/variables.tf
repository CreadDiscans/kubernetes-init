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

variable "username" {
  type    = string
  default = "admin"
}

variable "password" {
  type    = string
  default = "defaultpassword"
}

variable "mode" {
  type    = string
  default = "staging"
}
