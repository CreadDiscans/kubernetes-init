module "filesystem" {
  source     = "../../utils/apply"
  yaml       = "${path.module}/yaml/filesystem.yaml"
  args = {
    size = var.single_node ? 1 : 2
    requireSafeReplicaSize = var.single_node ? false : true
    podAntiAffinity = var.single_node ? false : true
  }
}