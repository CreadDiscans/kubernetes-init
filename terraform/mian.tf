module "nginx_ingress" {
  source       = "./nginx_ingress"
  external_ips = local.external_ips
  email        = local.email
}

module "gitlab_devops" {
  source        = "./gitlab_devops"
  domain        = local.domain
  root_password = local.gitlab_root_password
}
