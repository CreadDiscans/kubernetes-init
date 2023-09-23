terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
    }
  }
}

provider "keycloak" {
  # Configuration options
  client_id                = "admin-cli"
  username                 = var.username
  password                 = var.password
  url                      = var.url
  tls_insecure_skip_verify = true
}
