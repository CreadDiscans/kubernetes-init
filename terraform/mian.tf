module "nginx_ingress" {
  source       = "./nginx_ingress"
  external_ips = var.external_ips
  email        = var.email
}

module "nfs_provisioner" {
  source   = "./nfs_provisioner"
  nfs_ip   = var.nfs_ip
  nfs_path = var.nfs_path
}

module "keycloak_sso" {
  source   = "./keycloak"
  domain   = var.domain
  mode     = var.mode
  username = var.username
  password = var.password
}

module "gitlab_devops" {
  source        = "./gitlab_devops"
  domain        = var.domain
  root_password = var.password
  nfs_ip        = var.nfs_ip
  nfs_path      = var.nfs_path
  mode          = var.mode
  depends_on    = [module.nginx_ingress]
}
