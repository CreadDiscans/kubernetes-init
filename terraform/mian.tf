locals {
  external_ips = "x.x.x.x-x.x.x.x"
  email        = ""
}

module "ingress" {
  source       = "./ingress"
  external_ips = local.external_ips
  email        = local.email
}
