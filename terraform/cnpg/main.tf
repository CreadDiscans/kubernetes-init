
module "operator" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cnpg-1.20.2.yaml"
}

data "kubernetes_secret" "creds" {
  metadata {
    name      = "minio-creds"
    namespace = "minio-storage"
  }
}

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name      = "minio-creds"
    namespace = "cnpg-system"
  }

  data = {
    MINIO_ACCESS_KEY = data.kubernetes_secret.creds.data.username
    MINIO_SECRET_KEY = data.kubernetes_secret.creds.data.password
  }
  depends_on = [module.operator]
}

resource "time_sleep" "wait" {
  create_duration = "40s"
  depends_on      = [module.operator]
}

resource "time_static" "current" {}

module "cluster" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cnpg-cluster.yaml"
  args = {
    current = time_static.current.rfc3339
  }
  depends_on = [time_sleep.wait]
}

module "backup_daily" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/backup-scheduled.yaml"
  depends_on = [module.cluster]
}