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

module "cnpg" {
  source = "./cnpg"
}

module "keycloak" {
  source      = "./keycloak"
  domain      = var.domain
  mode        = var.mode
  username    = var.username
  password    = var.password
  db_password = module.cnpg.keycloak_db_password
  depends_on  = [module.nginx, module.cnpg]
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

module "argocd" {
  source     = "./argocd"
  mode       = var.mode
  domain     = var.domain
  depends_on = [module.keycloak]
}

module "gitlab" {
  source     = "./gitlab"
  domain     = var.domain
  password   = var.password
  mode       = var.mode
  depends_on = [module.nginx]
}

module "sso" {
  source   = "./sso"
  username = var.username
  password = var.password
  domain   = var.domain
  url      = module.keycloak.url
  clients = [
    module.minio.client,
    module.prometheus.client,
    module.autoscaler.client,
    module.argocd.client
  ]
}

module "spark" {
  source = "./spark"
}

