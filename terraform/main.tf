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
  source      = "./cnpg"
  minio_creds = local.minio_creds
  depends_on  = [module.nfs]
}

module "gitlab" {
  source   = "./gitlab"
  domain   = var.domain
  password = var.password
  prefix = {
    gitlab   = var.prefix.gitlab
    registry = var.prefix.registry
  }
  depends_on = [module.nginx, module.cnpg]
}

module "minio" {
  source = "./minio"
  domain = var.domain
  prefix = {
    minio  = var.prefix.minio
    gitlab = var.prefix.gitlab
  }
  password    = var.password
  minio_creds = local.minio_creds
  depends_on  = [module.gitlab]
}

# module "prometheus" {
#   source     = "./prometheus"
#   domain     = var.domain
#   mode       = var.mode
#   oidc       = var.grafana_oidc
#   depends_on = [module.gitlab]
# }

# module "argocd" {
#   source     = "./argocd"
#   mode       = var.mode
#   domain     = var.domain
#   oidc       = var.argocd_oidc
#   depends_on = [module.gitlab]
# }

# module "airflow" {
#   source     = "./airflow"
#   mode       = var.mode
#   domain     = var.domain
#   git_repo   = var.airflow_repo
#   oidc       = var.airflow_oidc
#   depends_on = [module.gitlab]
# }

# module "kubeflow" {
#   source     = "./kubeflow"
#   mode       = var.mode
#   domain     = var.domain
#   depends_on = [module.istio, module.gitlab]
# }

# # module "redis" {
# #   source = "./redis"
# # }

# # module "spark" {
# #   source = "./spark"
# #   mode   = var.mode
# #   domain = var.domain
# # }

# module "sso" {
#   source = "./sso"
#   domain = var.domain
#   clients = [{
#     prefix        = "kubeflow",
#     client_id     = var.kubeflow_oidc.client_id
#     client_secret = var.kubeflow_oidc.client_secret
#   }]

# }
