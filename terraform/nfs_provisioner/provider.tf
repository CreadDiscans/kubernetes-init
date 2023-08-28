terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

variable "nfs_ip" {
  type = string
}

variable "nfs_path" {
  type = string
}
