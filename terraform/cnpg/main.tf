
module "operator" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cnpg-1.20.2.yaml"
}

resource "kubernetes_secret" "minio-creds" {
  metadata {
    name      = "minio-creds"
    namespace = "cnpg-system"
  }

  data = {
    MINIO_ACCESS_KEY = var.username
    MINIO_SECRET_KEY = var.password
  }
  depends_on = [module.operator]
}

resource "time_sleep" "wait" {
  create_duration = "40s"
  depends_on      = [module.operator]
}

module "cluster" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/cnpg-cluster.yaml"
  depends_on = [time_sleep.wait]
}
