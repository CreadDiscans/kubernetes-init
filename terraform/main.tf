module "nginx" {
  source       = "./nginx"
  external_ips = var.external_ips
  email        = var.email
}

module "nfs" {
  source   = "./nfs"
  nfs_ip   = var.nfs_ip
  nfs_path = var.nfs_path
}

module "istio" {
  source = "./istio"
}

module "keycloak" {
  source     = "./keycloak"
  domain     = var.domain
  mode       = var.mode
  username   = var.username
  password   = var.password
  depends_on = [module.nginx]
}

module "minio" {
  source     = "./minio"
  domain     = var.domain
  mode       = var.mode
  depends_on = [module.nfs, module.keycloak]
}

module "prometheus" {
  source     = "./prometheus"
  domain     = var.domain
  mode       = var.mode
  depends_on = [module.keycloak]
}

module "autoscaler" {
  source     = "./autoscaler"
  domain     = var.domain
  mode       = var.mode
  depends_on = [module.prometheus]
}

module "sso" {
  source   = "./sso"
  username = var.username
  password = var.password
  domain   = var.domain
  url      = module.keycloak.url
  clients  = [
    module.minio.client,
    module.prometheus.client,
    module.autoscaler.client
  ]
}

# module "cnpg" {
#   source     = "./cnpg"
#   username   = var.username
#   password   = var.password
#   depends_on = [module.minio_storage]
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
