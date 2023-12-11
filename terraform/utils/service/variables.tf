locals {
  clusterissuer = "letsencrypt-prod"
}

variable "domain" {
  type = string
}

variable "prefix" {
  type = string
}

variable "namespace" {
  type = string
}

variable "port" {
  type = any
}

variable "selector" {
  type = any
}

variable "gateway" {
  type    = bool
  default = false
}
