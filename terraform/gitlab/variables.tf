locals {
  prefix          = "gitlab"
  prefix_registry = "reg"
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
