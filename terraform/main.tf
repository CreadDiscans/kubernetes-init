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

module "minio" {
  source     = "./minio"
  domain     = var.domain
  mode       = var.mode
  oidc       = var.minio_oidc
  depends_on = [module.nfs]
}

module "cnpg" {
  source     = "./cnpg"
  depends_on = [module.minio]
}

module "gitlab" {
  source     = "./gitlab"
  domain     = var.domain
  password   = var.password
  mode       = var.mode
  depends_on = [module.nginx]
}

module "prometheus" {
  source     = "./prometheus"
  domain     = var.domain
  mode       = var.mode
  oidc       = var.grafana_oidc
  depends_on = [module.gitlab]
}

module "argocd" {
  source     = "./argocd"
  mode       = var.mode
  domain     = var.domain
  oidc       = var.argocd_oidc
  depends_on = [module.gitlab]
}

module "airflow" {
  source   = "./airflow"
  mode     = var.mode
  domain   = var.domain
  git_repo = var.airflow_repo
  oidc     = var.airflow_oidc
}

# module "redis" {
#   source = "./redis"
# }


# module "keycloak" {
#   source     = "./keycloak"
#   domain     = var.domain
#   mode       = var.mode
#   username   = var.username
#   password   = var.password
#   depends_on = [module.nginx, module.cnpg]
# }


# module "spark" {
#   source = "./spark"
#   mode   = var.mode
#   domain = var.domain
# }

# module "kubeflow" {
#   source     = "./kubeflow"
#   mode       = var.mode
#   domain     = var.domain
#   depends_on = [module.istio]
# }

# module "sso" {
#   source   = "./sso"
#   username = var.username
#   password = var.password
#   domain   = var.domain
#   url      = module.keycloak.url
#   clients = [
#     module.minio.client,
#     module.prometheus.client,
#     module.argocd.client,
#     module.spark.client,
#     module.airflow.client,
#     module.kubeflow.client
#   ]
# }
