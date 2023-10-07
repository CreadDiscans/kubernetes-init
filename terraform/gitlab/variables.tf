locals {
  prefix          = "gitlab"
  prefix_registry = "registry"
}

variable "domain" {
  type = string
}

variable "password" {
  type = string
}

variable "mode" {
  type = string
}
