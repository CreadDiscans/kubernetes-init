terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

provider "keycloak" {
  # Configuration options
  client_id                = "admin-cli"
  username                 = var.keycloak.username
  password                 = var.keycloak.password
  url                      = var.keycloak.url
  tls_insecure_skip_verify = true
}
