# terraform {
#   required_version = ">= 0.13"

#   required_providers {
#     kubectl = {
#       source  = "gavinbunney/kubectl"
#       version = ">= 1.7.0"
#     }
#   }
# }

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# provider "kubectl" {
#   config_path = "~/.kube/config"
# }
