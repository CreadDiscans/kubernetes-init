module "nginx_ingress" {
  source       = "./nginx_ingress"
  external_ips = var.external_ips
  email        = var.email
}

module "prometheus_monitoring" {
  source     = "./prometheus-monitoring"
  domain     = var.domain
  mode       = var.mode
  depends_on = [module.nginx_ingress]
}

module "autoscaler" {
  source     = "./autoscaler"
  depends_on = [module.prometheus_monitoring]
  domain     = var.domain
  mode       = var.mode
}

module "nfs_provisioner" {
  source   = "./nfs_provisioner"
  nfs_ip   = var.nfs_ip
  nfs_path = var.nfs_path
}

module "minio_storage" {
  source     = "./minio_storage"
  domain     = var.domain
  mode       = var.mode
  username   = var.username
  password   = var.password
  depends_on = [module.nfs_provisioner]
}

# module "cnpg" {
#   source     = "./cnpg"
#   depends_on = [module.nfs_provisioner]
# }

# module "keycloak_sso" {
#   source   = "./keycloak"
#   domain   = var.domain
#   mode     = var.mode
#   username = var.username
#   password = var.password
# }


# module "gitlab_devops" {
#   source     = "./gitlab_devops"
#   domain     = var.domain
#   password   = var.password
#   nfs_ip     = var.nfs_ip
#   nfs_path   = var.nfs_path
#   mode       = var.mode
#   depends_on = [module.nginx_ingress]
# }
