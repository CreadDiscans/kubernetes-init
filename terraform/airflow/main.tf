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

data "kubernetes_secret" "gitlab_secret" {
  metadata {
    name      = "gitlab-secret"
    namespace = "gitlab-devops"
  }
}

module "oidc" {
  source       = "../utils/oidc"
  keycloak     = var.keycloak
  client_id    = local.client_id
  prefix       = local.prefix
  domain       = var.domain
  redirect_uri = ["https://${local.prefix}.${var.domain}/oauth-authorized/keycloak"]
}

module "airflow" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/airflow.yaml"
  args = {
    git_repo      = "https://root:${urlencode(data.kubernetes_secret.gitlab_secret.data.GITLAB_ROOT_PASSWORD)}@${replace(var.airflow_repo, "https://", "")}"
    connection    = "{\"conn_type\":\"aws\",\"extra\":{\"host\":\"${var.minio_creds.url}\",\"aws_access_key_id\":\"${var.minio_creds.username}\",\"aws_secret_access_key\":\"${var.minio_creds.password}\"}}"
    client_id     = module.oidc.auth.client_id
    client_secret = module.oidc.auth.client_secret
    keycloak_url  = module.oidc.auth.keycloak.url
    realm         = module.oidc.auth.realm
  }
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    tier      = "airflow"
    component = "webserver"
    release   = "airflow"
  }
  annotations = {
    "sysflow/favicon" = "/static/pin_32.png"
    "sysflow/doc"     = "https://airflow.apache.org/docs/apache-airflow/stable/index.html"
  }
  depends_on = [module.airflow]
}
