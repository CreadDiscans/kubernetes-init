resource "null_resource" "cert-manager" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/yaml/cert-manager-v1.12.3.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/yaml/cert-manager-v1.12.3.yaml"
  }
}

resource "time_sleep" "wait-cert-manager" {
  create_duration = "180s"
  depends_on      = [null_resource.cert-manager]
}

resource "kubectl_manifest" "cert-cluster-issuer-stage" {
  yaml_body = templatefile("${path.module}/yaml/cluster-issuer-stage.yaml", {
    email = var.email
  })
  depends_on = [time_sleep.wait-cert-manager]
}
resource "kubectl_manifest" "cert-cluster-issuer-prod" {
  yaml_body = templatefile("${path.module}/yaml/cluster-issuer-prod.yaml", {
    email = var.email
  })
  depends_on = [time_sleep.wait-cert-manager]
}
