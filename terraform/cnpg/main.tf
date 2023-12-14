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
  yaml       = "${path.module}/yaml/cnpg-1.20.2.yaml"
  depends_on = [kubernetes_namespace.ns]
}

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name      = "minio-creds"
    namespace = "cnpg-system"
  }

  data = {
    MINIO_ACCESS_KEY = var.minio_creds.username
    MINIO_SECRET_KEY = var.minio_creds.password
  }
  depends_on = [module.operator]
}

resource "time_sleep" "wait" {
  create_duration = "80s"
  depends_on      = [module.operator]
}

resource "time_static" "current" {}

module "airflow" {
  source     = "./service"
  name       = "airflow"
  depends_on = [time_sleep.wait]
}

module "gitlab" {
  source     = "./service"
  name       = "gitlab"
  depends_on = [time_sleep.wait]
}

module "cluster" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/cnpg-cluster.yaml"
  args = {
    current = time_static.current.rfc3339
    services = [
      module.airflow.info,
      module.gitlab.info
    ]
  }
  depends_on = [time_sleep.wait]
}

module "backup_weekly" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/backup-scheduled.yaml"
  depends_on = [module.cluster]
}

resource "kubernetes_service" "export_cnpg" {
  metadata {
    name      = "cnpg-service"
    namespace = "cnpg-system"
  }
  lifecycle {
    ignore_changes = [
      metadata.0.annotations
    ]
  }
  spec {
    selector = {
      "cnpg.io/cluster" = "cluster-cnpg"
      role              = "primary"
    }
    port {
      port        = 5432
      target_port = 5432
    }
    type = "LoadBalancer"
  }
  depends_on = [module.cluster]
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = <<EOF
      while true; do
        if [ $(kubectl get pod cluster-cnpg-1 -n cnpg-system 2> /dev/null | grep -c Running) -eq 1 ]
        then
            break
        else
            sleep 10
        fi
      done
    EOF
  }
  depends_on = [module.cluster]
}

resource "null_resource" "wait2" {
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l cnpg.io/podRole=instance -n cnpg-system"
  }
  depends_on = [null_resource.wait]
}