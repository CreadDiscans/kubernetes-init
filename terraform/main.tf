module "metallb" {
  source       = "./metallb"
  external_ips = var.external_ips
}

module "nginx" {
  source = "./nginx"
}

module "cloudflare" {
  source = "./cloudflare"
  token  = var.cloudflared_token
}

module "certmanager" {
  source  = "./certmanager"
  aws_key = var.aws_key
}

module "istio" {
  source = "./istio"
}

module "reloader" {
  source = "./reloader"
}

module "prometheus" {
  source = "./prometheus"
}

module "rook" {
  source      = "./rook/core"
  osd         = var.osd
  single_node = var.single_node
}

module "rook-storageclass" {
  source      = "./rook/storageclass"
  single_node = var.single_node
  depends_on  = [module.rook]
}

# module "nfs" {
#   source   = "./nfs"
#   nfs_info = var.nfs_info
# }

module "pihole" {
  source      = "./pihole"
  dns_records = var.dns_records
}

module "keycloak" {
  source = "./keycloak"
  route  = var.route
  prefix = var.prefix.keycloak
}

module "grafana" {
  source   = "./grafana"
  route    = var.route
  prefix   = var.prefix.grafana
  keycloak = module.keycloak.info
}

module "argocd" {
  source   = "./argocd"
  route    = var.route
  prefix   = var.prefix.argocd
  keycloak = module.keycloak.info
}

module "minio" {
  source = "./minio"
  route  = var.route
  prefix = {
    console = var.prefix.minio
    api     = var.prefix.minio_api
  }
  keycloak = module.keycloak.info
}

module "gitlab" {
  source = "./gitlab"
  route  = var.route
  prefix = {
    gitlab   = var.prefix.gitlab
    registry = var.prefix.registry
  }
  keycloak = module.keycloak.info
}

module "kubeflow" {
  source   = "./kubeflow"
  route    = var.route
  prefix   = var.prefix.kubeflow
  email    = var.email
  keycloak = module.keycloak.info
}

module "sysflow" {
  source       = "./sysflow"
  route        = var.route
  grafana      = module.grafana.info
  kubeflow_url = module.kubeflow.url
  keycloak     = module.keycloak.info
}

module "airflow" {
  source       = "./airflow"
  route        = var.route
  prefix       = var.prefix.airflow
  minio_creds  = module.minio.creds
  keycloak     = module.keycloak.info
  airflow_repo = "${module.gitlab.gitlab_url}${var.airflow_repo}"
}

module "milvus" {
  source   = "./milvus"
  route    = var.route
  prefix   = var.prefix.milvus
  keycloak = module.keycloak.info
}

module "spark" {
  source   = "./spark"
  route    = var.route
  prefix   = var.prefix.spark
  keycloak = module.keycloak.info
}

module "jenkins" {
  source   = "./jenkins"
  route    = var.route
  keycloak = module.keycloak.info
}

module "presto" {
  source   = "./presto"
  route    = var.route
  keycloak = module.keycloak.info
}

module "opencost" {
  source   = "./opencost"
  route    = var.route
  keycloak = module.keycloak.info
}

module "superset" {
  source   = "./superset"
  route    = var.route
  keycloak = module.keycloak.info
}

module "auth" {
  source = "./auth"
  auths = [
    module.kubeflow.auth,
    module.milvus.auth,
    module.spark.auth,
    module.presto.auth,
    module.opencost.auth
  ]
}

module "cnpg" {
  source = "./cnpg"
}

module "vitess" {
  source = "./vitess"
}

# module "langfuse" {
#   source      = "./langfuse"
#   route       = var.route
#   keycloak    = module.keycloak.info
#   minio_creds = module.minio.creds
# }
