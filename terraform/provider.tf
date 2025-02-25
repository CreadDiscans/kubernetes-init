terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
