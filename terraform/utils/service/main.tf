resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.prefix}-service"
    namespace = var.namespace
  }
  spec {
    selector = var.selector
    port {
      name        = "http"
      port        = 80
      target_port = var.port
    }
    port {
      name        = "https"
      port        = 443
      target_port = var.port
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "${var.prefix}-ingress"
    annotations = merge({
      "kubernetes.io/ingress.class"                   = "nginx"
      "nginx.ingress.kubernetes.io/proxy-buffer-size" = "128k"
      }, var.route.issuer == "" ? {} : {
      "cert-manager.io/cluster-issuer"     = var.route.issuer
      "kubernetes.io/tls-acme"             = "true"
      "ingress.kubernetes.io/ssl-redirect" = "true"
    }, var.annotations)
    namespace = var.gateway != "" ? "istio-system" : var.namespace
  }
  spec {
    ingress_class_name = "nginx"
    dynamic "tls" {
      for_each = var.route.issuer == "" ? [] : [1]
      content {
        hosts       = ["${var.prefix}.${var.route.domain}"]
        secret_name = "${var.prefix}-cert"
      }
    }
    rule {
      host = "${var.prefix}.${var.route.domain}"

      http {
        path {
          path = "/"
          backend {
            service {
              name = var.gateway != "" ? "istio-ingressgateway" : kubernetes_service.service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "time_sleep" "wait" {
  count           = var.gateway != "" ? 1 : 0
  create_duration = "10s"
  depends_on      = [kubernetes_ingress_v1.ingress]
}

data "template_file" "gateway" {
  template = file("${path.module}/yaml/gateway.yaml")
  vars = {
    gateway   = var.gateway
    name      = var.prefix
    namespace = var.namespace
    hostname  = "${var.prefix}.${var.route.domain}"
  }
  depends_on = [time_sleep.wait]
}

resource "null_resource" "gateway" {
  count = var.gateway != "" ? 1 : 0

  triggers = {
    template = data.template_file.gateway.rendered
  }

  provisioner "local-exec" {
    when    = create
    command = "kubectl create -f -<<EOF\n${self.triggers.template}\nEOF"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f -<<EOF\n${self.triggers.template}\nEOF"
  }
}

data "template_file" "vertual_service" {
  template = file("${path.module}/yaml/virtual-service.yaml")
  vars = {
    gateway   = var.gateway
    name      = var.prefix
    namespace = var.namespace
    hostname  = "${var.prefix}.${var.route.domain}"
  }
  depends_on = [time_sleep.wait]
}

resource "null_resource" "vertual_service" {
  count = var.gateway != "" ? 1 : 0

  triggers = {
    template = data.template_file.vertual_service.rendered
  }

  provisioner "local-exec" {
    when    = create
    command = "kubectl create -f -<<EOF\n${self.triggers.template}\nEOF"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f -<<EOF\n${self.triggers.template}\nEOF"
  }
}
