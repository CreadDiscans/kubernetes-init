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

module "prometheus" {
  source   = "./prometheus"
  domain   = var.domain
  prefix   = var.prefix.grafana
  keycloak = module.keycloak.info
}

module "argocd" {
  source   = "./argocd"
  domain   = var.domain
  prefix   = var.prefix.argocd
  keycloak = module.keycloak.info
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
  source = "./gitlab"
  domain = var.domain
  prefix = {
    gitlab   = var.prefix.gitlab
    registry = var.prefix.registry
  }
  keycloak = module.keycloak.info
}

module "airflow" {
  source       = "./airflow"
  domain       = var.domain
  prefix       = var.prefix.airflow
  minio_creds  = module.minio.creds
  keycloak     = module.keycloak.info
  airflow_repo = var.airflow_repo
}

module "kubeflow" {
  source      = "./kubeflow"
  domain      = var.domain
  prefix      = var.prefix.kubeflow
  email       = var.email
  minio_creds = module.minio.creds
  keycloak    = module.keycloak.info
}

module "milvus" {
  source = "./milvus"
  domain = var.domain
  prefix = var.prefix.milvus
  minio_creds = module.minio.creds
}
