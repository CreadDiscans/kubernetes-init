data "kubernetes_secret" "pv_secret" {
  metadata {
    name = "${var.name}-pv"
  }
}

resource "null_resource" "pv_unclaim" {
  count = data.kubernetes_secret.pv_secret.data == null ? 0 : 1
  provisioner "local-exec" {
    command = "kubectl patch pv ${data.kubernetes_secret.pv_secret.data.name} -p '{\"spec\":{\"claimRef\": null}}'"
  }
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "${var.name}-pvc"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "nfs-volume"
    volume_name        = data.kubernetes_secret.pv_secret.data == null ? null : data.kubernetes_secret.pv_secret.data.name
  }
}

resource "null_resource" "make_pv_secret" {
  provisioner "local-exec" {
    command = "kubectl create secret generic ${var.name}-pv --save-config --dry-run=client --from-literal=name=${kubernetes_persistent_volume_claim.pvc.spec.0.volume_name} -o yaml | kubectl apply -f -"
  }
}
