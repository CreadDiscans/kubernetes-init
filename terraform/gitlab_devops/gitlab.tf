resource "kubernetes_namespace" "ns" {
  metadata {
    name = "gitlab-devops"
  }
}

resource "kubernetes_deployment" "gitlab_deploy" {
  metadata {
    name      = "gitlab-deploy"
    namespace = kubernetes_namespace.ns.metadata[0].name
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
          image = "gitlab/gitlab-ce:16.3.0-ce.0"
          name  = "gitlab"
          env {
            name  = "TZ"
            value = "Asia/Seoul"
          }
          env {
            name  = "GITLAB_ROOT_PASSWORD"
            value = var.root_password
          }
          env {
            name  = "GITLAB_SKIP_UNMIGRATED_DATA_CHECK"
            value = true
          }
        }
      }
    }
  }
}

resource "time_sleep" "wait_deploy" {
  create_duration = "60s"
  depends_on      = [kubernetes_deployment.gitlab_deploy]
}

resource "kubernetes_service" "gitlab_service" {
  metadata {
    name      = "gitlab-service"
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.gitlab_deploy.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
  depends_on = [time_sleep.wait_deploy]
}

resource "kubernetes_ingress_v1" "gitlab_ingress" {
  metadata {
    name = "gitalb-ingress"
    annotations = {
      "ingress.kubernetes.io/ssl-redirect" = "true"
      "kubernetes.io/ingress.class"        = "nginx"
      "kubernetes.io/tls-acme"             = "true"
      "cert-manager.io/cluster-issuer"     = "letsencrypt-prod"
    }
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    tls {
      hosts       = ["gitlab.${var.domain}"]
      secret_name = "gitlab-cert"
    }
    rule {
      host = "gitlab.${var.domain}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.gitlab_service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [time_sleep.wait_deploy]
}
