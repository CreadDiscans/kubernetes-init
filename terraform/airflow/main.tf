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

module "oidc" {
  source       = "../utils/oidc"
  namespace    = kubernetes_namespace.ns.metadata.0.name
  gitlab_host  = "https://${var.prefix.gitlab}.${var.domain}"
  password     = var.password
  redirect_uri = "https://${var.prefix.airflow}.${var.domain}/oauth-authorized/gitlab"
  name         = "airflow"
}

data "kubernetes_secret" "oidc_secret" {
  metadata {
    name      = module.oidc.secret
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
}

module "airflow" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/airflow.yaml"
  args = {
    git_repo      = "https://root:${var.password}@${var.prefix.gitlab}.${var.domain}/consoleAdmin/airflow"
    connection    = "{\"conn_type\":\"aws\",\"extra\":{\"host\":\"${local.minio_url}\",\"aws_access_key_id\":\"${var.minio_creds.username}\",\"aws_secret_access_key\":\"${var.minio_creds.password}\"}}"
    client_id     = data.kubernetes_secret.oidc_secret.data.client_id
    client_secret = data.kubernetes_secret.oidc_secret.data.client_secret
    domain        = var.domain
  }
  depends_on = [time_sleep.wait]
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.airflow
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    tier      = "airflow"
    component = "webserver"
    release   = "airflow"
  }
  depends_on = [module.airflow]
}
