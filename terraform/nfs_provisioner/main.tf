
resource "null_resource" "nfs" {
  provisioner "local-exec" {
    command = "kubectl create -f ${path.module}/yaml/nfs-provisioner-v4.0.18.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/yaml/nfs-provisioner-v4.0.18.yaml"
  }
}

resource "kubectl_manifest" "nfs_deploy" {
  yaml_body = templatefile("${path.module}/yaml/nfs-provisioner-deploy.yaml", {
    server_ip   = var.nfs_ip
    server_path = var.nfs_path
  })
}
