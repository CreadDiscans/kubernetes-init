locals {
  prefix = "airflow"
}

variable "mode" {
  type = string
}

variable "domain" {
  type = string
}

variable "git_repo" {
  type = string
}
