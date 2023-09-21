resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.prefix}-service"
    namespace = var.namespace
  }
  spec {
    selector = var.selector
    port {
      port        = 80
      target_port = var.port
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "${var.prefix}-ingress"
    annotations = {
      "ingress.kubernetes.io/ssl-redirect"            = "true"
      "kubernetes.io/ingress.class"                   = "nginx"
      "kubernetes.io/tls-acme"                        = "true"
      "cert-manager.io/cluster-issuer"                = local.clusterissuer
      "nginx.ingress.kubernetes.io/proxy-buffer-size" = "128k"
    }
    namespace = var.gateway ? "istio-system" : var.namespace
  }
  spec {
    tls {
      hosts       = ["${var.prefix}.${var.domain}"]
      secret_name = "${var.prefix}-cert"
    }
    rule {
      host = "${var.prefix}.${var.domain}"

      http {
        path {
          path = "/"
          backend {
            service {
              name = var.gateway ? "istio-ingressgateway" : kubernetes_service.service.metadata.0.name
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
  count           = var.gateway ? 1 : 0
  create_duration = "10s"
  depends_on      = [kubernetes_ingress_v1.ingress]
}

data "template_file" "gateway" {
  template = file("${path.module}/yaml/gateway.yaml")
  vars = {
    name      = var.prefix
    namespace = var.namespace
    hostname  = "${var.prefix}.${var.domain}"
  }
  depends_on = [time_sleep.wait]
}

resource "null_resource" "gateway" {
  count = var.gateway ? 1 : 0

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
    name      = var.prefix
    namespace = var.namespace
    hostname  = "${var.prefix}.${var.domain}"
  }
  depends_on = [time_sleep.wait]
}

resource "null_resource" "vertual_service" {
  count = var.gateway ? 1 : 0

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
