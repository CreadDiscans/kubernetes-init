module "nfs" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/nfs-provisioner-v4.0.18.yaml"
}

module "nfs_deploy" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/nfs-provisioner-deploy.yaml"
  args = {
    server_ip   = var.nfs_info.ip
    server_path = var.nfs_info.path
  }
  depends_on = [module.nfs]
}
