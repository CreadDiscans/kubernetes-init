locals {
  external_ips = "x.x.x.x-x.x.x.x"
  email        = ""
}

module "nginx_ingress" {
  source       = "./nginx_ingress"
  external_ips = local.external_ips
  email        = local.email
}
