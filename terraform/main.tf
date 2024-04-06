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
  prefix     = var.prefix.keycloak
  admin      = var.admin
  depends_on = [module.nfs, module.nginx]
}

module "minio" {
  source   = "./minio"
  domain   = var.domain
  prefix   = var.prefix.minio
  keycloak = module.keycloak.info
}

module "cnpg" {
  source      = "./cnpg"
  minio_creds = module.minio.creds
}

module "gitlab" {
  source   = "./gitlab"
  domain   = var.domain
  prefix = {
    gitlab   = var.prefix.gitlab
    registry = var.prefix.registry
  }
  keycloak = module.keycloak.info
}

module "prometheus" {
  source = "./prometheus"
  domain = var.domain
  prefix = var.prefix.grafana
  keycloak = module.keycloak.info
}

# module "argocd" {
#   source = "./argocd"
#   domain = var.domain
#   prefix = {
#     argocd = var.prefix.argocd
#     gitlab = var.prefix.gitlab
#   }
#   password   = var.password
#   depends_on = [module.prometheus]
# }

# module "airflow" {
#   source = "./airflow"
#   domain = var.domain
#   prefix = {
#     airflow = var.prefix.airflow
#     gitlab  = var.prefix.gitlab
#   }
#   password    = var.password
#   minio_creds = local.minio_creds
#   depends_on  = [module.argocd]
# }

# module "kubeflow" {
#   source = "./kubeflow"
#   domain = var.domain
#   prefix = {
#     kubeflow = var.prefix.kubeflow
#     gitlab   = var.prefix.gitlab
#   }
#   password    = var.password
#   email       = var.email
#   minio_creds = local.minio_creds
#   depends_on  = [module.istio, module.airflow]
# }
