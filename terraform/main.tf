module "metallb" {
  source       = "./metallb"
  external_ips = var.external_ips
}

module "nginx" {
  source = "./nginx"
}

module "certmanager" {
  source = "./certmanager"
  email  = var.email
}

module "istio" {
  source = "./istio"
}

module "reloader" {
  source = "./reloader"
}

module "rook" {
  source      = "./rook/core"
  osd         = var.osd
  domain      = var.domain
  single_node = var.single_node
}

module "rook-storgeclass" {
  source      = "./rook/storageclass"
  single_node = var.single_node
  depends_on  = [module.rook]
}

# module "nfs" {
#   source   = "./nfs"
#   nfs_ip   = var.nfs_ip
#   nfs_path = var.nfs_path
# }

module "keycloak" {
  source = "./keycloak"
  domain = var.domain
}

module "prometheus" {
  source   = "./prometheus"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "argocd" {
  source   = "./argocd"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "minio" {
  source   = "./minio"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "gitlab" {
  source   = "./gitlab"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "kubeflow" {
  source   = "./kubeflow"
  domain   = var.domain
  email    = var.email
  keycloak = module.keycloak.info
}

module "sysflow" {
  source = "./sysflow"
  domain = var.domain
  grafana = {
    url  = module.prometheus.url
    path = "/d/85a562078cdf77779eaa1add43ccec1e/kubernetes-compute-resources-namespace-pods"
  }
  kubeflow_url = module.kubeflow.url
  keycloak     = module.keycloak.info
}

module "airflow" {
  source       = "./airflow"
  domain       = var.domain
  minio_creds  = module.minio.creds
  keycloak     = module.keycloak.info
  airflow_repo = "${module.gitlab.gitlab_url}${var.airflow_repo}"
}

module "milvus" {
  source      = "./milvus"
  domain      = var.domain
  keycloak    = module.keycloak.info
}

module "spark" {
  source   = "./spark"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "jenkins" {
  source   = "./jenkins"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "presto" {
  source   = "./presto"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "opencost" {
  source   = "./opencost"
  domain   = var.domain
  keycloak = module.keycloak.info
}

module "superset" {
  source   = "./superset"
  domain   = var.domain
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
