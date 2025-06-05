locals {
  client_id = "grafana"
  namespace = "monitoring"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type    = string
  default = "grafana"
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
    url  = "https://${var.prefix}.${var.route.domain}"
    path = "/d/85a562078cdf77779eaa1add43ccec1e/kubernetes-compute-resources-namespace-pods"
  }
}
