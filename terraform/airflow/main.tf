resource "kubernetes_namespace" "ns" {
  metadata {
    name = "airflow"
  }
}

resource "random_password" "password" {
  length = 16
}

resource "kubernetes_secret" "webserver_secret" {
  metadata {
    name      = "webserver-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    webserver-secret-key = random_password.password.result
  }
}

data "kubernetes_secret" "db" {
  metadata {
    name      = "airflow-db-secret"
    namespace = "cnpg-system"
  }
}

resource "kubernetes_secret" "cnpg_db" {
  metadata {
    name      = "cnpg-db"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    connection = "postgresql://${data.kubernetes_secret.db.data.username}:${data.kubernetes_secret.db.data.password}@cluster-cnpg-rw.cnpg-system:5432/${data.kubernetes_secret.db.data.db_name}"
  }
}

data "kubernetes_secret" "minio" {
  metadata {
    name      = "minio-creds"
    namespace = "minio-storage"
  }
}

module "airflow" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/airflow.yaml"
  args = {
    git_repo      = var.git_repo
    connection    = "{\"conn_type\":\"aws\",\"extra\":{\"host\":\"${local.minio_url}\",\"aws_access_key_id\":\"${data.kubernetes_secret.minio.data.username}\",\"aws_secret_access_key\":\"${data.kubernetes_secret.minio.data.password}\"}}"
    client_id     = local.client_id
    client_secret = local.client_secret
    domain        = var.domain
  }
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  gateway   = true
  selector = {
    tier      = "airflow"
    component = "webserver"
    release   = "airflow"
  }
  depends_on = [module.airflow]
}
