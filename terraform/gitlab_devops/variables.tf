locals {
  prefix = "gitlab"
}

variable "domain" {
  type = string
}

variable "root_password" {
  type = string
}

variable "nfs_ip" {
  type = string
}

variable "nfs_path" {
  type = string
}
