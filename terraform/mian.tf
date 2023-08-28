module "nginx_ingress" {
  source       = "./nginx_ingress"
  external_ips = local.external_ips
  email        = local.email
}

module "nfs_provisioner" {
  source   = "./nfs_provisioner"
  nfs_ip   = local.nfs_ip
  nfs_path = local.nfs_path
}

module "gitlab_devops" {
  source        = "./gitlab_devops"
  domain        = local.domain
  root_password = local.gitlab_root_password
  depends_on    = [module.nginx_ingress]
}
