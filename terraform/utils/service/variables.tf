locals {
  clusterissuer = var.mode == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"
}

variable "mode" {
  type = string
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
