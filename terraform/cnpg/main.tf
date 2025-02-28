resource "kubernetes_namespace" "ns" {
  metadata {
    name = "cnpg-system"
    labels = {
      "app.kubernetes.io/name" = "cloudnative-pg"
    }
  }
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/cnpg-1.25.0.yaml"
  depends_on = [kubernetes_namespace.ns]
}

# resource "kubernetes_secret" "minio_creds" {
#   metadata {
#     name      = "minio-creds"
#     namespace = "cnpg-system"
#   }

#   data = {
#     MINIO_ACCESS_KEY = var.minio_creds.username
#     MINIO_SECRET_KEY = var.minio_creds.password
#   }
#   depends_on = [module.operator]
# }

# module "cluster" {
#   source = "../utils/apply"
#   yaml   = "${path.module}/yaml/cnpg-cluster.yaml"
#   args = {
#     current = time_static.current.rfc3339
#     minio_url = var.minio_creds.url
#     services = [
#       module.airflow.info,
#       module.gitlab.info
#     ]
#   }
#   depends_on = [time_sleep.wait]
# }

# module "backup_weekly" {
#   source     = "../utils/apply"
#   yaml       = "${path.module}/yaml/backup-scheduled.yaml"
#   depends_on = [module.cluster]
# }
