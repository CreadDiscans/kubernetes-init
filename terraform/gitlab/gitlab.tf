resource "kubernetes_namespace" "ns" {
  metadata {
    name = "gitlab-devops"
  }
}

module "volume" {
  source    = "../utils/volume"
  name      = "gitlab"
  namespace = kubernetes_namespace.ns.metadata.0.name
}

resource "kubernetes_deployment" "gitlab_deploy" {
  metadata {
    name      = "gitlab-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "gitlab"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "gitlab"
      }
    }
    template {
      metadata {
        labels = {
          app = "gitlab"
        }
      }
      spec {
        container {
          image = "gitlab/gitlab-ce:16.4.1-ce.0"
          name  = "gitlab"
          env {
            name  = "TZ"
            value = "Asia/Seoul"
          }
          env {
            name  = "GITLAB_ROOT_PASSWORD"
            value = var.password
          }
          env {
            name  = "GITLAB_SKIP_UNMIGRATED_DATA_CHECK"
            value = true
          }
          volume_mount {
            mount_path = "/etc/gitlab"
            name       = "gitlab-volume"
            sub_path   = "gitlab/config"
          }
          volume_mount {
            mount_path = "/var/opt/gitlab"
            name       = "gitlab-volume"
            sub_path   = "gitlab/data"
          }
        }
        volume {
          name = "gitlab-volume"
          persistent_volume_claim {
            claim_name = module.volume.pvc_name
          }
        }
      }
    }
  }
}

resource "time_sleep" "wait_deploy" {
  create_duration = "180s"
  depends_on      = [kubernetes_deployment.gitlab_deploy]
}

module "service" {
  source    = "../utils/service"
  mode      = var.mode
  domain    = var.domain
  prefix    = local.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 80
  selector = {
    app = "gitlab"
  }
  depends_on = [time_sleep.wait_deploy]
}
