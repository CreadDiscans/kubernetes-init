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

module "gitlab_devops" {
  source        = "./gitlab_devops"
  domain        = var.domain
  root_password = var.gitlab_root_password
  depends_on    = [module.nginx_ingress]
}
