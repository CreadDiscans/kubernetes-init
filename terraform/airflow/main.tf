resource "kubernetes_namespace" "ns" {
  metadata {
    name = "airflow"
  }
}

resource "kubernetes_secret" "webserver_secret" {
  metadata {
    name      = "webserver-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    webserver-secret-key = local.password
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

data "kubernetes_secret" "gitlab_secret" {
  metadata {
    name      = "gitlab-secret"
    namespace = "gitlab-devops"
  }
}

module "airflow" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/airflow.yaml"
  args = {
    git_repo      = "https://root:${urlencode(data.kubernetes_secret.gitlab_secret.data.GITLAB_ROOT_PASSWORD)}@${var.airflow_repo}"
    connection    = "{\"conn_type\":\"aws\",\"extra\":{\"host\":\"${var.minio_creds.url}\",\"aws_access_key_id\":\"${var.minio_creds.username}\",\"aws_secret_access_key\":\"${var.minio_creds.password}\"}}"
    client_id     = local.client_id
    client_secret = local.client_secret
    keycloak_url  = var.keycloak.url
    realm         = local.realm
  }
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    tier      = "airflow"
    component = "webserver"
    release   = "airflow"
  }
  depends_on = [module.airflow]
}
