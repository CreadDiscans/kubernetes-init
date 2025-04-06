locals {
  prefix    = "grafana"
  client_id = "grafana"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
    email  = string
  })
}

variable "keycloak" {
  type = object({
    url      = string
    username = string
    password = string
  })
}

output "info" {
  value = {
    url  = "https://${local.prefix}.${var.route.domain}"
    path = "/d/85a562078cdf77779eaa1add43ccec1e/kubernetes-compute-resources-namespace-pods"
  }
}
